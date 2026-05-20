from fastapi import APIRouter, Depends, Request
from sqlalchemy.orm import Session
from typing import List, Optional
from datetime import datetime

from ...database import get_db
from ...dependencies import get_admin_user, limiter
from ...services.admin_service import AdminService
from ... import schemas

router = APIRouter(prefix="/audit-logs", tags=["Admin Audit Logs"])


@router.get("/", response_model=List[schemas.AuditLogSchema])
@limiter.limit("60/minute")
def get_audit_logs(
    request: Request,
    admin_id: Optional[str] = None,
    action: Optional[str] = None,
    target_type: Optional[str] = None,
    from_date: Optional[datetime] = None,
    to_date: Optional[datetime] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin=Depends(get_admin_user),
):
    """
    Query the admin audit trail with optional filters.
    Only accessible by admins.

    Filters:
    - `admin_id`: show actions by a specific admin
    - `action`: partial match on action name (e.g. 'ban', 'hide')
    - `target_type`: user | comment | report | notification
    - `from_date` / `to_date`: ISO datetime range filter
    """
    service = AdminService(db)
    return service.get_audit_logs(
        admin_id=admin_id,
        action=action,
        target_type=target_type,
        from_date=from_date,
        to_date=to_date,
        skip=skip,
        limit=min(limit, 500),
    )
