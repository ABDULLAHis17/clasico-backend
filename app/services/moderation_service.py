from sqlalchemy.orm import Session
from .. import models
from datetime import datetime
import re

class ModerationService:
    """
    AI Content Moderation Service.
    Predicts toxicity scores and handles automated flagging.
    """

    def __init__(self, db: Session):
        self.db = db

    def score_text(self, text: str) -> float:
        """
        Predicts a toxicity score (0.0 to 1.0) for a given text.
        In this implementation, we use a hybrid approach:
        1. A heuristic-based keyword check for common toxic terms.
        2. Placeholder for an external AI API call (e.g., Google Perspective API).
        """
        if not text:
            return 0.0

        # 1. Heuristic: Check for common toxic keywords (Arabic & English)
        toxic_keywords = [
            # English
            r"fuck", r"shit", r"bitch", r"asshole", r"idiot", r"stupid", r"hate",
            # Arabic (Common toxic patterns/insults)
            r"غبي", r"حمار", r"كلب", r"حقير", r"زفت", r"تفو", r"شتم", r"سب"
        ]
        
        score = 0.0
        text_lower = text.lower()
        
        matches = 0
        for pattern in toxic_keywords:
            if re.search(pattern, text_lower):
                matches += 1
        
        # Simple score based on matches
        if matches > 0:
            score = min(0.4 + (matches * 0.15), 0.95)
        else:
            # Baseline for non-detectable toxicity
            score = 0.05

        return score

    def flag_comment(self, comment_id: str) -> float:
        """
        Analyzes a comment, updates its toxicity score in the database,
        and logs the moderation attempt.
        """
        comment = self.db.query(models.Comment).filter(models.Comment.id == comment_id).first()
        if not comment:
            return 0.0
        
        score = self.score_text(comment.content)
        comment.toxicity_score = score
        
        # Log to comment_moderation_logs
        log = models.CommentModerationLog(
            comment_id=comment_id,
            checked_by=models.ModerationChecker.ai,
            action=models.ModerationAction.allow if score < 0.7 else models.ModerationAction.delete,
            reason=f"AI toxicity score: {score:.2f}",
            ai_score=score
        )
        self.db.add(log)
        
        # Auto-hide if highly toxic
        if score >= 0.8:
            comment.is_hidden = True
            comment.deleted_at = datetime.utcnow()
        
        self.db.commit()
        return score

    def process_pending_comments(self):
        """Analyze all comments that haven't been scored yet."""
        pending = self.db.query(models.Comment).filter(models.Comment.toxicity_score == None).limit(100).all() # noqa
        for comment in pending:
            self.flag_comment(comment.id)
