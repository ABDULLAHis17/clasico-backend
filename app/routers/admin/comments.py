from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from typing import Optional, List

from ...database import get_db
from ...dependencies import get_moderator_user, limiter
from ...services.admin_service import AdminService
from ... import schemas

router = APIRouter(prefix="/comments", tags=["Admin Comment Moderation"])


@router.get("/reported")
@limiter.limit("30/minute")
def get_reported_comments(
    request: Request,
    auto_hide_threshold: int = 5,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """
    List all comments that have been reported, with report count per comment.
    Flags comments exceeding `auto_hide_threshold` for mass action.
    NOTE: This route is defined BEFORE /{id} to avoid routing conflicts.
    """
    service = AdminService(db)
    return service.get_reported_comments(auto_hide_threshold)


@router.post("/auto-hide")
@limiter.limit("10/minute")
def trigger_auto_hide(
    request: Request,
    threshold: int = 5,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """
    Auto-hide all comments whose report_count >= threshold.
    Returns the number of comments hidden.
    """
    service = AdminService(db)
    count = service.trigger_auto_hide(threshold)
    return {"message": f"Auto-hidden {count} comments with report_count >= {threshold}"}


@router.get("/", response_model=List[schemas.CommentDetailSchema])
@limiter.limit("60/minute")
def get_comments(
    request: Request,
    is_hidden: Optional[bool] = None,
    min_reports: Optional[int] = None,
    entity_type: Optional[str] = None,
    skip: int = 0,
    limit: int = 100,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """
    List comments with optional filters:
    - `is_hidden`: show only hidden or visible comments
    - `min_reports`: show only comments with >= this many reports
    - `entity_type`: filter by entity (match | news | transfer | club | player)
    """
    service = AdminService(db)
    return service.list_comments(
        is_hidden=is_hidden,
        min_reports=min_reports,
        entity_type=entity_type,
        skip=skip,
        limit=min(limit, 500),
    )


@router.delete("/{id}")
@limiter.limit("30/minute")
def delete_comment(
    request: Request,
    id: str,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """Soft-delete (hide + set deleted_at) a comment. Logged to audit trail."""
    service = AdminService(db)
    comment = service.delete_comment(id, admin.id)
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    return {"message": "Comment deleted successfully", "comment_id": id}


@router.patch("/{id}/hide")
@limiter.limit("30/minute")
def hide_comment(
    request: Request,
    id: str,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """Hide a comment from public view without marking it as deleted."""
    service = AdminService(db)
    comment = service.hide_comment(id, admin.id)
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    return {"message": "Comment hidden successfully", "comment_id": id}


@router.patch("/{id}/unhide")
@limiter.limit("30/minute")
def unhide_comment(
    request: Request,
    id: str,
    db: Session = Depends(get_db),
    admin=Depends(get_moderator_user),
):
    """Restore a previously hidden comment back to public visibility."""
    service = AdminService(db)
    comment = service.unhide_comment(id, admin.id)
    if not comment:
        raise HTTPException(status_code=404, detail="Comment not found")
    return {"message": "Comment restored successfully", "comment_id": id}
