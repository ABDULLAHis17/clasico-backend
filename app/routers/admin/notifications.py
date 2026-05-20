from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session

from ...database import get_db
from ...dependencies import get_admin_user, limiter
from ...services.admin_service import AdminService
from ... import schemas

router = APIRouter(prefix="/notifications", tags=["Admin Notifications"])


@router.post("/broadcast")
@limiter.limit("10/minute")
def broadcast_notification(
    request: Request,
    body: schemas.NotificationBroadcastSchema,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """
    Send a notification to ALL active users.
    Creates UserNotification rows for every recipient.
    Rate limited to 10/minute to prevent abuse.
    Logged to audit trail with recipient count.
    """
    service = AdminService(db)
    result = service.broadcast_notification(
        title=body.title,
        body=body.body,
        payload=body.payload or {},
        admin_id=admin.id,
        ip_address=request.client.host,
    )
    return {"message": "Broadcast sent successfully", **result}


@router.post("/team")
@limiter.limit("10/minute")
def team_notification(
    request: Request,
    body: schemas.TeamNotificationSchema,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """
    Send a notification to all users who follow a specific team.
    Targets the `favorite_teams` table to find recipients.
    """
    service = AdminService(db)
    result = service.team_notification(
        team_id=body.team_id,
        title=body.title,
        body=body.body,
        payload=body.payload or {},
        admin_id=admin.id,
        ip_address=request.client.host,
    )
    return {"message": "Team notification sent successfully", **result}


@router.post("/league")
@limiter.limit("10/minute")
def league_notification(
    request: Request,
    body: schemas.LeagueNotificationSchema,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """
    Send a notification to all users who follow a specific league.
    Targets the `favorite_leagues` table to find recipients.
    """
    service = AdminService(db)
    result = service.league_notification(
        league_id=body.league_id,
        title=body.title,
        body=body.body,
        payload=body.payload or {},
        admin_id=admin.id,
        ip_address=request.client.host,
    )
    return {"message": "League notification sent successfully", **result}
