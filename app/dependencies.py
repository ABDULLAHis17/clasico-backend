from fastapi import Depends, HTTPException, Request, status
from fastapi.security import OAuth2PasswordBearer
from jose import JWTError
from sqlalchemy.orm import Session
from slowapi import Limiter
from slowapi.util import get_remote_address
import os

from . import models, schemas, auth
from .database import get_db

# ─────────────────────────────────────────────────────────────
# Rate Limiter (slowapi)
# ─────────────────────────────────────────────────────────────
limiter = Limiter(key_func=get_remote_address)

# ─────────────────────────────────────────────────────────────
# OAuth2 scheme
# ─────────────────────────────────────────────────────────────
oauth2_scheme = OAuth2PasswordBearer(tokenUrl="token")


# ─────────────────────────────────────────────────────────────
# Core user resolution
# ─────────────────────────────────────────────────────────────
async def get_current_user(
    token: str = Depends(oauth2_scheme),
    db: Session = Depends(get_db),
) -> models.User:
    credentials_exception = HTTPException(
        status_code=status.HTTP_401_UNAUTHORIZED,
        detail="Could not validate credentials",
        headers={"WWW-Authenticate": "Bearer"},
    )
    try:
        payload = auth.decode_token(token)
        user_id: str = payload.get("sub")
        if user_id is None:
            raise credentials_exception
    except JWTError:
        raise credentials_exception

    user = db.query(models.User).filter(models.User.id == user_id).first()
    if user is None:
        raise credentials_exception
    return user


async def get_current_active_user(
    current_user: models.User = Depends(get_current_user),
) -> models.User:
    """Returns the user only if their account is active (not banned)."""
    if current_user.status == "banned":
        raise HTTPException(
            status_code=status.HTTP_403_FORBIDDEN,
            detail="Your account has been suspended.",
        )
    if current_user.status != "active":
        raise HTTPException(
            status_code=status.HTTP_400_BAD_REQUEST,
            detail="Inactive user account.",
        )
    return current_user


# ─────────────────────────────────────────────────────────────
# RBAC helpers
# ─────────────────────────────────────────────────────────────
def check_role(required_roles: list):
    """Factory that returns a dependency checking if the user has one of the required roles."""
    async def role_checker(
        current_user: models.User = Depends(get_current_active_user),
    ) -> models.User:
        user_roles = [role.name for role in current_user.roles]
        if not any(role in user_roles for role in required_roles):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="You do not have enough permissions to access this resource.",
            )
        return current_user
    return role_checker


# Role-based dependency shortcuts
get_admin_user = check_role(["admin"])
get_moderator_user = check_role(["admin", "moderator"])


# ─────────────────────────────────────────────────────────────
# Ban-scope check (for game-only bans)
# ─────────────────────────────────────────────────────────────
def check_game_ban(game_code: str = None):
    """
    Dependency factory. When injected into a game endpoint, verifies the user
    doesn't have an active game-only (or full) ban covering this game.
    """
    async def ban_checker(
        current_user: models.User = Depends(get_current_active_user),
        db: Session = Depends(get_db),
    ) -> models.User:
        from datetime import datetime
        from sqlalchemy import or_
        active_ban = (
            db.query(models.Ban)
            .filter(
                models.Ban.user_id == current_user.id,
                models.Ban.is_active == True,  # noqa
                or_(
                    models.Ban.expires_at == None,  # noqa  permanent
                    models.Ban.expires_at > datetime.utcnow(),
                ),
            )
            .first()
        )
        if active_ban:
            ban_scope = active_ban.ban_scope or "full"
            if ban_scope in ("full", "permanent", "temporary", "game-only"):
                # game-only: only block if game_code matches or scope == full
                if ban_scope in ("full", "permanent", "temporary"):
                    raise HTTPException(
                        status_code=status.HTTP_403_FORBIDDEN,
                        detail=f"You are banned: {active_ban.reason}",
                    )
                if ban_scope == "game-only":
                    meta = active_ban.metadata_json or {}
                    banned_game = meta.get("game_code") or meta.get("game_id")
                    if game_code and banned_game == game_code:
                        raise HTTPException(
                            status_code=status.HTTP_403_FORBIDDEN,
                            detail=f"You are banned from this game: {active_ban.reason}",
                        )
        return current_user
    return ban_checker


# ─────────────────────────────────────────────────────────────
# Global IP Ban Check
# ─────────────────────────────────────────────────────────────
async def check_ip_ban(
    request: Request,
    db: Session = Depends(get_db),
):
    """
    Dependency that can be used globally or on specific routers 
    to block banned IP addresses.
    """
    try:
        from .services.user_service import UserService
        ip = request.client.host
        service = UserService(db)
        if service.is_ip_banned(ip):
            raise HTTPException(
                status_code=status.HTTP_403_FORBIDDEN,
                detail="Your IP address has been banned from this service.",
            )
        return ip
    except Exception as e:
        # If DB is not ready, we don't want to block everything with 500
        print(f"⚠️ Warning: check_ip_ban failed (DB might not be ready): {e}")
        return request.client.host
