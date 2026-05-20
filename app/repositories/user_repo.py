from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from .. import models, schemas
from typing import List, Optional
from datetime import datetime, timedelta


class UserRepository:
    """Data-access layer for user-specific operations."""

    def __init__(self, db: Session):
        self.db = db

    def get_user_by_id(self, user_id: str) -> Optional[models.User]:
        return self.db.query(models.User).filter(models.User.id == user_id).first()

    def get_users(self, skip: int = 0, limit: int = 100) -> List[models.User]:
        return self.db.query(models.User).offset(skip).limit(limit).all()

    def get_user_roles(self, user_id: str) -> List[models.Role]:
        user = self.get_user_by_id(user_id)
        return user.roles if user else []

    def get_user_by_email(self, email: str) -> Optional[models.User]:
        return self.db.query(models.User).filter(models.User.email == email).first()

    def create_user(self, user_in: schemas.UserCreateSchema, hashed_password: str) -> models.User:
        user = models.User(
            id=user_in.email,  # Using email as ID for simplicity in seeding, or change to UUID
            email=user_in.email,
            hashed_password=hashed_password,
            status="active"
        )
        self.db.add(user)
        self.db.flush()
        
        # Create profile
        profile = models.UserProfile(
            user_id=user.id,
            display_name=user_in.display_name or user_in.email.split('@')[0]
        )
        self.db.add(profile)
        
        # Assign 'user' role by default
        user_role = self.db.query(models.Role).filter(models.Role.name == "user").first()
        if user_role:
            user.roles.append(user_role)
            
        self.db.commit()
        self.db.refresh(user)
        return user

    def update_user_role(self, user_id: str, role_names: List[str]) -> Optional[models.User]:
        user = self.get_user_by_id(user_id)
        if not user:
            return None
        roles = self.db.query(models.Role).filter(models.Role.name.in_(role_names)).all()
        user.roles = roles
        self.db.commit()
        self.db.refresh(user)
        return user

    def ban_user(
        self,
        user_id: str,
        admin_id: str,
        ban_type: str,
        ban_scope: str = "full",
        reason: str = "",
        expires_at: Optional[datetime] = None,
        metadata_json: Optional[dict] = None,
        ip_address: Optional[str] = None,
    ) -> models.Ban:
        ban = models.Ban(
            user_id=user_id,
            admin_id=admin_id,
            type=ban_type,
            ban_scope=ban_scope,
            reason=reason,
            expires_at=expires_at,
            is_active=True,
            metadata_json=metadata_json or {},
            ip_address=ip_address,
        )
        self.db.add(ban)

        # Only mark user as 'banned' if it's a full-account ban
        if ban_scope in ("full", "permanent", "temporary"):
            user = self.get_user_by_id(user_id)
            if user:
                user.status = "banned"

        self.db.commit()
        self.db.refresh(ban)
        return ban

    def unban_user(self, user_id: str) -> Optional[models.User]:
        """Soft-deactivate all active bans and restore user account status."""
        # Deactivate bans (soft delete – keep history)
        self.db.query(models.Ban).filter(
            models.Ban.user_id == user_id,
            models.Ban.is_active == True,  # noqa
        ).update({"is_active": False}, synchronize_session="fetch")

        user = self.get_user_by_id(user_id)
        if user:
            user.status = "active"
            self.db.commit()
        return user

    def get_online_users_count(self) -> int:
        five_minutes_ago = datetime.utcnow() - timedelta(minutes=5)
        return (
            self.db.query(models.UserDevice.user_id)
            .filter(models.UserDevice.last_seen_at >= five_minutes_ago)
            .distinct()
            .count()
        )

    def get_total_users_count(self) -> int:
        return self.db.query(models.User).count()

    def is_ip_banned(self, ip_address: str) -> bool:
        """Check if an IP address is currently banned."""
        return (
            self.db.query(models.Ban)
            .filter(
                models.Ban.ip_address == ip_address,
                models.Ban.is_active == True,  # noqa
                or_(
                    models.Ban.expires_at == None,  # noqa permanent
                    models.Ban.expires_at > datetime.utcnow(),
                ),
            )
            .first() is not None
        )
