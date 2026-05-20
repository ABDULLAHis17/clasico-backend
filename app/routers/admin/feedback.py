from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import List, Optional

from ...database import get_db
from ...dependencies import get_moderator_user, limiter
from ...services.admin_service import AdminService
from ... import schemas

router = APIRouter(prefix="/feedback", tags=["Admin Feedback Management"])

@router.get("/", response_model=List[schemas.ReportSchema])
@limiter.limit("60/minute")
def get_feedback(
    request: Request,
    status: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """
    List user feedback submitted via the settings screen.
    Feedback is stored as Reports with entity_type='feedback'.
    """
    service = AdminService(db)
    # We reuse list_reports but lock the entity_type to 'feedback'
    return service.list_reports(
        status=status,
        entity_type="feedback",
        skip=skip,
        limit=min(limit, 500),
    )


@router.patch("/{id}/resolve")
@limiter.limit("30/minute")
def resolve_feedback(
    request: Request,
    id: int,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """Mark feedback as resolved. Logged to audit trail."""
    service = AdminService(db)
    # We reuse the resolve_report logic since feedback is stored as a report
    report = service.resolve_report(id, admin.id, "resolved")
    if not report:
        raise HTTPException(status_code=404, detail="Feedback not found")
    return {"message": "Feedback resolved successfully", "id": id}


@router.patch("/{id}/reject")
@limiter.limit("30/minute")
def reject_feedback(
    request: Request,
    id: int,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """Mark feedback as rejected."""
    service = AdminService(db)
    report = service.resolve_report(id, admin.id, "rejected")
    if not report:
        raise HTTPException(status_code=404, detail="Feedback not found")
    return {"message": "Feedback rejected successfully", "id": id}
