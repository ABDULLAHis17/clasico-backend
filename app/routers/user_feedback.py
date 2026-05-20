from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from datetime import datetime

from ..database import get_db
from ..dependencies import limiter
from .. import models, schemas

router = APIRouter(prefix="/feedback", tags=["Public Feedback"])

@router.post("/")
@limiter.limit("5/hour")
def submit_feedback(
    request: Request,
    feedback: schemas.FeedbackCreateSchema,
    db: Session = Depends(get_db)
):
    """
    Public endpoint for users to submit feedback from the app settings.
    Stored in the reports table with entity_type='feedback'.
    """
    
    # We append the email to the reason if provided so admin can contact them
    reason_text = feedback.message
    if feedback.email:
        reason_text += f"\n\n--- Contact Email ---\n{feedback.email}"
        
    new_report = models.Report(
        reporter_id="system_public", # Since it might be an unauthenticated user
        target_id="system",
        entity_type="feedback",
        reason=reason_text,
        status="pending",
        created_at=datetime.utcnow()
    )
    
    db.add(new_report)
    db.commit()
    db.refresh(new_report)
    
    return {"message": "Feedback submitted successfully", "id": new_report.id}
