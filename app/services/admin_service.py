from sqlalchemy.orm import Session
from sqlalchemy import func
from .. import models, schemas
from ..repositories.admin_repo import AdminRepository
from typing import List, Optional
from datetime import datetime
import uuid


class AdminService:
    """
    Business logic layer for admin operations.
    All mutations are logged to audit_logs via log_action().
    """

    def __init__(self, db: Session):
        self.db = db
        self.repo = AdminRepository(db)

    # ─── Audit Logging ───────────────────────────────────────────

    def log_action(
        self,
        admin_id: str,
        action: str,
        target_id: str,
        target_type: str = "user",
        metadata: dict = None,
        ip_address: str = None,
    ) -> models.AuditLog:
        log = models.AuditLog(
            admin_id=admin_id,
            action=action,
            target_id=str(target_id),
            target_type=target_type,
            metadata_json=metadata or {},
            ip_address=ip_address,
        )
        self.db.add(log)
        self.db.commit()
        return log

    # ─── Dashboard ───────────────────────────────────────────────

    def get_dashboard_stats(self) -> dict:
        return self.repo.get_dashboard_stats()

    def get_online_users_count(self) -> int:
        return self.repo.get_online_users_count()

    def get_top_players(self, limit: int = 10) -> List[dict]:
        return self.repo.get_top_players(limit)

    # ─── Audit Logs ──────────────────────────────────────────────

    def get_audit_logs(
        self,
        admin_id: Optional[str] = None,
        action: Optional[str] = None,
        target_type: Optional[str] = None,
        from_date: Optional[datetime] = None,
        to_date: Optional[datetime] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[models.AuditLog]:
        return self.repo.get_audit_logs_filtered(
            admin_id=admin_id,
            action=action,
            target_type=target_type,
            from_date=from_date,
            to_date=to_date,
            skip=skip,
            limit=limit,
        )

    # ─── Reports ─────────────────────────────────────────────────

    def list_reports(
        self,
        status: Optional[str] = None,
        entity_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[models.Report]:
        return self.repo.list_reports_filtered(status, entity_type, skip, limit)

    def resolve_report(self, report_id: int, admin_id: str, status: str) -> Optional[models.Report]:
        report = self.db.query(models.Report).filter(models.Report.id == report_id).first()
        if report:
            report.status = status
            report.resolved_at = datetime.utcnow()
            report.resolved_by = admin_id
            self.db.commit()
            self.log_action(
                admin_id=admin_id,
                action=f"report_{status}",
                target_id=str(report_id),
                target_type="report",
                metadata={"entity_type": report.entity_type, "target_id": report.target_id},
            )
        return report

    # ─── Comments ────────────────────────────────────────────────

    def list_comments(
        self,
        is_hidden: Optional[bool] = None,
        min_reports: Optional[int] = None,
        entity_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[models.Comment]:
        return self.repo.list_comments_filtered(is_hidden, min_reports, entity_type, skip, limit)

    def get_reported_comments(self, auto_hide_threshold: int = 5) -> List[dict]:
        return self.repo.get_reported_comments(auto_hide_threshold)

    def hide_comment(self, comment_id: str, admin_id: str) -> Optional[models.Comment]:
        comment = self.db.query(models.Comment).filter(models.Comment.id == comment_id).first()
        if comment:
            comment.is_hidden = True
            comment.deleted_at = datetime.utcnow()
            self.db.commit()
            self.log_action(
                admin_id=admin_id,
                action="hide_comment",
                target_id=comment_id,
                target_type="comment",
            )
        return comment

    def unhide_comment(self, comment_id: str, admin_id: str) -> Optional[models.Comment]:
        comment = self.db.query(models.Comment).filter(models.Comment.id == comment_id).first()
        if comment:
            comment.is_hidden = False
            comment.deleted_at = None
            self.db.commit()
            self.log_action(
                admin_id=admin_id,
                action="unhide_comment",
                target_id=comment_id,
                target_type="comment",
            )
        return comment

    def delete_comment(self, comment_id: str, admin_id: str) -> Optional[models.Comment]:
        comment = self.db.query(models.Comment).filter(models.Comment.id == comment_id).first()
        if comment:
            comment.is_hidden = True
            comment.deleted_at = datetime.utcnow()
            self.db.commit()
            self.log_action(
                admin_id=admin_id,
                action="delete_comment",
                target_id=comment_id,
                target_type="comment",
            )
        return comment

    def trigger_auto_hide(self, threshold: int = 5) -> int:
        count = self.repo.auto_hide_comments(threshold)
        self.db.commit()
        return count

    # ─── Notifications ───────────────────────────────────────────

    def _create_notification(self, title: str, body: str, payload: dict) -> models.Notification:
        notif = models.Notification(
            id=str(uuid.uuid4()),
            type=models.NotificationType.custom,
            title=title,
            body=body,
            payload_json=payload or {},
        )
        self.db.add(notif)
        self.db.flush()  # get ID without committing
        return notif

    def _bulk_send_notification(self, notification_id: str, user_ids: List[str]):
        """Bulk-insert UserNotification rows for all recipients."""
        rows = [
            models.UserNotification(
                notification_id=notification_id,
                user_id=uid,
            )
            for uid in user_ids
        ]
        self.db.bulk_save_objects(rows)

    def broadcast_notification(
        self, title: str, body: str, payload: dict, admin_id: str, ip_address: str = None
    ) -> dict:
        notif = self._create_notification(title, body, payload)
        user_ids = self.repo.get_all_user_ids()
        self._bulk_send_notification(notif.id, user_ids)
        self.db.commit()
        self.log_action(
            admin_id=admin_id,
            action="broadcast_notification",
            target_id=notif.id,
            target_type="notification",
            metadata={"title": title, "recipients": len(user_ids)},
            ip_address=ip_address,
        )
        return {"notification_id": notif.id, "recipients": len(user_ids)}

    def team_notification(
        self, team_id: str, title: str, body: str, payload: dict, admin_id: str, ip_address: str = None
    ) -> dict:
        notif = self._create_notification(title, body, payload)
        user_ids = self.repo.get_team_follower_ids(team_id)
        self._bulk_send_notification(notif.id, user_ids)
        self.db.commit()
        self.log_action(
            admin_id=admin_id,
            action="team_notification",
            target_id=team_id,
            target_type="notification",
            metadata={"title": title, "recipients": len(user_ids), "notification_id": notif.id},
            ip_address=ip_address,
        )
        return {"notification_id": notif.id, "recipients": len(user_ids), "team_id": team_id}

    def league_notification(
        self, league_id: str, title: str, body: str, payload: dict, admin_id: str, ip_address: str = None
    ) -> dict:
        notif = self._create_notification(title, body, payload)
        user_ids = self.repo.get_league_follower_ids(league_id)
        self._bulk_send_notification(notif.id, user_ids)
        self.db.commit()
        self.log_action(
            admin_id=admin_id,
            action="league_notification",
            target_id=league_id,
            target_type="notification",
            metadata={"title": title, "recipients": len(user_ids), "notification_id": notif.id},
            ip_address=ip_address,
        )
        return {"notification_id": notif.id, "recipients": len(user_ids), "league_id": league_id}
