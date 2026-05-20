from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import Optional

from ...database import get_db
from ...dependencies import get_admin_user, limiter
from ...services.admin_service import AdminService
from ...services.user_service import UserService
from ... import schemas

router = APIRouter(prefix="/dashboard", tags=["Admin Dashboard"])


@router.get("/stats", response_model=schemas.DashboardStatsSchema)
@limiter.limit("30/minute")
def get_stats(
    request: Request,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """Full dashboard stats: user counts, bans, reports, comments."""
    service = AdminService(db)
    return service.get_dashboard_stats()


@router.get("/online-users")
@limiter.limit("30/minute")
def get_online_users(
    request: Request,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """Count of users active in the last 5 minutes."""
    service = AdminService(db)
    return {"online_users": service.get_online_users_count()}


@router.get("/top-players")
@limiter.limit("30/minute")
def get_top_players(
    request: Request,
    limit: int = 10,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """Top players ranked by best score from user_best_scores table."""
    service = AdminService(db)
    return service.get_top_players(min(limit, 50))
