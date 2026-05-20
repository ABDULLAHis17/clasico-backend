from sqlalchemy.orm import Session
from sqlalchemy import or_
from ..repositories.user_repo import UserRepository
from ..repositories.admin_repo import AdminRepository
from .. import models, schemas
from typing import List, Optional
from datetime import datetime, timedelta


class UserService:
    """
    Business logic layer for user management (admin context).
    Handles ban lifecycle, role management, and user queries.
    """

    def __init__(self, db: Session):
        self.db = db
        self.repo = UserRepository(db)
        self.admin_repo = AdminRepository(db)

    # ─── Listing & Details ───────────────────────────────────────

    def list_users(
        self,
        search: Optional[str] = None,
        status: Optional[str] = None,
        role: Optional[str] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[models.User]:
        return self.admin_repo.list_users_filtered(search, status, role, skip, limit)

    def get_user_details(self, user_id: str) -> Optional[models.User]:
        return self.admin_repo.get_user_with_details(user_id)

    def get_user_full(self, user_id: str) -> Optional[dict]:
        """Return user data with active ban attached for the API response."""
        user = self.admin_repo.get_user_with_details(user_id)
        if not user:
            return None
        active_ban = self.admin_repo.get_active_ban(user_id)
        return {"user": user, "active_ban": active_ban}

    def get_dashboard_stats(self) -> dict:
        return self.admin_repo.get_dashboard_stats()

    # ─── Role Management ─────────────────────────────────────────

    def change_user_role(
        self,
        target_user_id: str,
        roles: List[str],
        requesting_admin: models.User,
    ) -> Optional[models.User]:
        """
        Change roles for a user.
        Security: prevents self-escalation, only admins can assign 'admin' role.
        """
        # Prevent self-modification of roles
        if target_user_id == requesting_admin.id:
            raise ValueError("Administrators cannot change their own roles.")

        # Only admins can assign the admin role
        if "admin" in roles:
            admin_roles = [r.name for r in requesting_admin.roles]
            if "admin" not in admin_roles:
                raise PermissionError("Only admins can assign the 'admin' role.")

        return self.repo.update_user_role(target_user_id, roles)

    # ─── Ban System ──────────────────────────────────────────────

    def issue_ban(
        self,
        user_id: str,
        admin_id: str,
        ban_type: str,
        reason: str,
        duration_days: Optional[int] = None,
        game_code: Optional[str] = None,
        ip_address: Optional[str] = None,
    ) -> models.Ban:
        """
        Issue a ban with full scope support:
        - temporary: requires duration_days, sets expires_at
        - permanent: no expiry, is_active=True indefinitely
        - game-only: no full account ban; stores game_code in metadata_json
        """
        expires_at = None
        ban_scope = "full"

        if ban_type == "temporary":
            if not duration_days:
                raise ValueError("duration_days required for temporary bans.")
            expires_at = datetime.utcnow() + timedelta(days=duration_days)

        if ban_type == "game-only":
            if not game_code:
                raise ValueError("game_code required for game-only bans.")
            ban_scope = "game-only"

        metadata = {}
        if game_code:
            metadata["game_code"] = game_code

        return self.repo.ban_user(
            user_id=user_id,
            admin_id=admin_id,
            ban_type=ban_type,
            ban_scope=ban_scope,
            reason=reason,
            expires_at=expires_at,
            metadata_json=metadata,
            ip_address=ip_address,
        )

    def is_ip_banned(self, ip_address: str) -> bool:
        return self.repo.is_ip_banned(ip_address)

    def lift_ban(self, user_id: str) -> Optional[models.User]:
        """Soft-deactivate all active bans and restore user status to active."""
        return self.repo.unban_user(user_id)

    def get_active_ban(self, user_id: str) -> Optional[models.Ban]:
        return self.admin_repo.get_active_ban(user_id)

    def is_banned_from_game(self, user_id: str, game_code: str) -> bool:
        """Check if user has an active game-only or full ban covering a specific game."""
        active_ban = self.admin_repo.get_active_ban(user_id)
        if not active_ban:
            return False
        scope = active_ban.ban_scope or "full"
        if scope == "full":
            return True
        if scope == "game-only":
            meta = active_ban.metadata_json or {}
            return meta.get("game_code") == game_code
        return False
