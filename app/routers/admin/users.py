from fastapi import APIRouter, Depends, HTTPException, Request, Body
from sqlalchemy.orm import Session
from typing import List, Optional

from ...database import get_db
from ...dependencies import get_admin_user, get_moderator_user, limiter
from ...services.user_service import UserService
from ...services.admin_service import AdminService
from ... import schemas, models

router = APIRouter(prefix="/users", tags=["Admin User Management"])


@router.get("/", response_model=List[schemas.UserSchema])
@limiter.limit("60/minute")
def get_users(
    request: Request,
    search: Optional[str] = None,
    status: Optional[str] = None,
    role: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """
    List users with optional filtering.
    - `search`: filter by email or display_name (partial match)
    - `status`: filter by account status (active | banned)
    - `role`: filter by role name (user | moderator | admin)
    """
    service = UserService(db)
    return service.list_users(search=search, status=status, role=role, skip=skip, limit=min(limit, 500))


@router.get("/{id}")
@limiter.limit("60/minute")
def get_user(
    request: Request,
    id: str,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """
    Get full user details: profile, roles, and active ban if any.
    Prevents IDOR – returns 404 for nonexistent users.
    """
    service = UserService(db)
    result = service.get_user_full(id)
    if not result:
        raise HTTPException(status_code=404, detail="User not found")

    user: models.User = result["user"]
    active_ban: Optional[models.Ban] = result["active_ban"]

    return {
        "id": user.id,
        "email": user.email,
        "status": user.status,
        "roles": [{"id": r.id, "name": r.name} for r in user.roles],
        "profile": {
            "display_name": user.profile.display_name if user.profile else None,
            "avatar_url": user.profile.avatar_url if user.profile else None,
            "country": user.profile.country if user.profile else None,
        },
        "active_ban": {
            "id": active_ban.id,
            "type": active_ban.type,
            "ban_scope": active_ban.ban_scope,
            "reason": active_ban.reason,
            "expires_at": active_ban.expires_at,
            "created_at": active_ban.created_at,
        } if active_ban else None,
        "created_at": user.created_at,
        "updated_at": user.updated_at,
    }


@router.patch("/{id}/role")
@limiter.limit("30/minute")
def update_user_role(
    request: Request,
    id: str,
    body: schemas.RoleUpdateSchema,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """
    Update a user's roles.
    Security:
    - Admins cannot change their own roles (self-escalation prevention).
    - Only admins can assign the 'admin' role (privilege escalation prevention).
    """
    service = UserService(db)
    admin_svc = AdminService(db)

    try:
        user = service.change_user_role(
            target_user_id=id,
            roles=body.roles,
            requesting_admin=admin,
        )
    except ValueError as e:
        raise HTTPException(status_code=400, detail=str(e))
    except PermissionError as e:
        raise HTTPException(status_code=403, detail=str(e))

    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    admin_svc.log_action(
        admin_id=admin.id,
        action="change_user_role",
        target_id=id,
        target_type="user",
        metadata={"new_roles": body.roles},
        ip_address=request.client.host,
    )
    return {"message": "User roles updated successfully", "user_id": id, "roles": body.roles}


@router.post("/{id}/ban")
@limiter.limit("30/minute")
def ban_user(
    request: Request,
    id: str,
    body: schemas.BanCreateSchema,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """
    Ban a user.
    - `temporary`: requires `duration_days`
    - `permanent`: no expiry
    - `game-only`: requires `game_code`; doesn't lock the full account

    Security: Admins cannot ban themselves.
    """
    if id == admin.id:
        raise HTTPException(status_code=400, detail="You cannot ban yourself.")

    service = UserService(db)
    admin_svc = AdminService(db)

    # Confirm user exists (IDOR protection)
    from ...repositories.admin_repo import AdminRepository
    target = AdminRepository(db).get_user_with_details(id)
    if not target:
        raise HTTPException(status_code=404, detail="User not found")

    try:
        ban = service.issue_ban(
            user_id=id,
            admin_id=admin.id,
            ban_type=body.type,
            reason=body.reason,
            duration_days=body.duration_days,
            game_code=body.game_code,
            ip_address=body.ip_address,
        )
    except ValueError as e:
        raise HTTPException(status_code=422, detail=str(e))

    admin_svc.log_action(
        admin_id=admin.id,
        action=f"ban_user_{body.type}",
        target_id=id,
        target_type="user",
        metadata={
            "ban_id": ban.id,
            "type": body.type,
            "reason": body.reason,
            "duration_days": body.duration_days,
            "game_code": body.game_code,
        },
        ip_address=request.client.host,
    )
    return {"message": "User banned successfully", "ban_id": ban.id, "type": body.type}


@router.post("/{id}/unban")
@limiter.limit("30/minute")
def unban_user(
    request: Request,
    id: str,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """Lift all active bans for a user and restore their account to active."""
    service = UserService(db)
    admin_svc = AdminService(db)

    user = service.lift_ban(id)
    if not user:
        raise HTTPException(status_code=404, detail="User not found")

    admin_svc.log_action(
        admin_id=admin.id,
        action="unban_user",
        target_id=id,
        target_type="user",
        ip_address=request.client.host,
    )
    return {"message": "User unbanned successfully", "user_id": id}
