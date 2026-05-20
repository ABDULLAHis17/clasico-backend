from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List, Optional

from ...database import get_db
from ...dependencies import get_moderator_user, limiter
from ...services.admin_service import AdminService
from ... import schemas

router = APIRouter(prefix="/reports", tags=["Admin Reports Management"])


@router.get("/", response_model=List[schemas.ReportSchema])
@limiter.limit("60/minute")
def get_reports(
    request: Request,
    status: Optional[str] = None,
    entity_type: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """
    List reports with optional filters:
    - `status`: pending | resolved | rejected
    - `entity_type`: user | comment
    """
    service = AdminService(db)
    return service.list_reports(
        status=status,
        entity_type=entity_type,
        skip=skip,
        limit=min(limit, 500),
    )


@router.patch("/{id}/resolve")
@limiter.limit("30/minute")
def resolve_report(
    request: Request,
    id: int,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """Mark a report as resolved. Logged to audit trail."""
    service = AdminService(db)
    report = service.resolve_report(id, admin.id, "resolved")
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return {"message": "Report resolved successfully", "report_id": id}


@router.patch("/{id}/reject")
@limiter.limit("30/minute")
def reject_report(
    request: Request,
    id: int,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """Mark a report as rejected. Logged to audit trail."""
    service = AdminService(db)
    report = service.resolve_report(id, admin.id, "rejected")
    if not report:
        raise HTTPException(status_code=404, detail="Report not found")
    return {"message": "Report rejected successfully", "report_id": id}
