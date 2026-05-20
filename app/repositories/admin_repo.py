from sqlalchemy.orm import Session
from sqlalchemy import func, or_
from .. import models
from typing import Optional, List
from datetime import datetime, timedelta


class AdminRepository:
    """
    Data-access layer for admin operations.
    Contains no business logic – only DB queries.
    """

    def __init__(self, db: Session):
        self.db = db

    # ─── Dashboard ────────────────────────────────────────────────

    def get_dashboard_stats(self) -> dict:
        """Return all counts needed for the admin dashboard in one call."""
        five_minutes_ago = datetime.utcnow() - timedelta(minutes=5)
        
        # Initialize all counts to 0
        total_users = 0
        active_users = 0
        banned_users = 0
        online_users = 0
        total_comments = 0
        hidden_comments = 0
        pending_reports = 0
        total_reports = 0
        open_bans = 0

        # Run each query in its own try-except to handle missing tables or broken data
        try:
            total_users = self.db.query(func.count(models.User.id)).scalar()
        except Exception: pass

        try:
            active_users = self.db.query(func.count(models.User.id)).filter(models.User.status == "active").scalar()
        except Exception: pass

        try:
            banned_users = self.db.query(func.count(models.User.id)).filter(models.User.status == "banned").scalar()
        except Exception: pass

        try:
            online_users = (
                self.db.query(models.UserDevice.user_id)
                .filter(models.UserDevice.last_seen_at >= five_minutes_ago)
                .distinct()
                .count()
            )
        except Exception: pass

        try:
            total_comments = self.db.query(func.count(models.Comment.id)).scalar()
        except Exception: pass

        try:
            hidden_comments = self.db.query(func.count(models.Comment.id)).filter(models.Comment.is_hidden == True).scalar() # noqa
        except Exception: pass

        try:
            pending_reports = self.db.query(func.count(models.Report.id)).filter(models.Report.status == "pending").scalar()
        except Exception: pass

        try:
            total_reports = self.db.query(func.count(models.Report.id)).scalar()
        except Exception: pass

        try:
            open_bans = self.db.query(func.count(models.Ban.id)).filter(models.Ban.is_active == True).scalar() # noqa
        except Exception: pass

        return {
            "total_users": total_users or 0,
            "active_users": active_users or 0,
            "banned_users": banned_users or 0,
            "online_users": online_users or 0,
            "total_comments": total_comments or 0,
            "hidden_comments": hidden_comments or 0,
            "pending_reports": pending_reports or 0,
            "total_reports": total_reports or 0,
            "open_bans": open_bans or 0,
        }

    def get_online_users_count(self) -> int:
        five_minutes_ago = datetime.utcnow() - timedelta(minutes=5)
        return (
            self.db.query(models.UserDevice.user_id)
            .filter(models.UserDevice.last_seen_at >= five_minutes_ago)
            .distinct()
            .count()
        )

    def get_top_players(self, limit: int = 10) -> List[dict]:
        """
        Return top users ordered by their best_score across all games.
        Joins user_best_scores with user_profiles for display_name.
        """
        results = (
            self.db.query(
                models.UserBestScore,
                models.UserProfile.display_name,
            )
            .outerjoin(
                models.UserProfile,
                models.UserProfile.user_id == models.UserBestScore.user_id,
            )
            .order_by(models.UserBestScore.best_score.desc())
            .limit(limit)
            .all()
        )
        return [
            {
                "user_id": row.UserBestScore.user_id,
                "display_name": row.display_name,
                "game_code": row.UserBestScore.game_code,
                "best_score": row.UserBestScore.best_score,
                "achieved_at": row.UserBestScore.achieved_at,
            }
            for row in results
        ]

    # ─── Users ───────────────────────────────────────────────────

    def list_users_filtered(
        self,
        search: Optional[str] = None,
        status: Optional[str] = None,
        role: Optional[str] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[models.User]:
        query = self.db.query(models.User)

        if search:
            query = query.outerjoin(models.UserProfile).filter(
                or_(
                    models.User.email.ilike(f"%{search}%"),
                    models.UserProfile.display_name.ilike(f"%{search}%"),
                )
            )

        if status:
            query = query.filter(models.User.status == status)

        if role:
            query = query.join(models.User.roles).filter(models.Role.name == role)

        return query.order_by(models.User.created_at.desc()).offset(skip).limit(limit).all()

    def get_user_with_details(self, user_id: str) -> Optional[models.User]:
        """Fetch user with profile, roles eagerly loaded."""
        from sqlalchemy.orm import joinedload
        return (
            self.db.query(models.User)
            .options(
                joinedload(models.User.profile),
                joinedload(models.User.roles),
            )
            .filter(models.User.id == user_id)
            .first()
        )

    # ─── Bans ────────────────────────────────────────────────────

    def get_active_ban(self, user_id: str) -> Optional[models.Ban]:
        """Return the most recent active ban for a user, if any."""
        return (
            self.db.query(models.Ban)
            .filter(
                models.Ban.user_id == user_id,
                models.Ban.is_active == True,  # noqa
                or_(
                    models.Ban.expires_at == None,  # noqa  permanent / game-only
                    models.Ban.expires_at > datetime.utcnow(),
                ),
            )
            .order_by(models.Ban.created_at.desc())
            .first()
        )

    def deactivate_bans(self, user_id: str) -> int:
        """Soft-deactivate all active bans for a user. Returns number of rows updated."""
        count = (
            self.db.query(models.Ban)
            .filter(models.Ban.user_id == user_id, models.Ban.is_active == True)  # noqa
            .update({"is_active": False}, synchronize_session="fetch")
        )
        return count

    # ─── Comments ────────────────────────────────────────────────

    def list_comments_filtered(
        self,
        is_hidden: Optional[bool] = None,
        min_reports: Optional[int] = None,
        entity_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[models.Comment]:
        query = self.db.query(models.Comment).filter(models.Comment.deleted_at == None)  # noqa

        if is_hidden is not None:
            query = query.filter(models.Comment.is_hidden == is_hidden)

        if min_reports is not None:
            query = query.filter(models.Comment.report_count >= min_reports)

        if entity_type:
            query = query.filter(models.Comment.entity_type == entity_type)

        return query.order_by(models.Comment.created_at.desc()).offset(skip).limit(limit).all()

    def get_reported_comments(self, auto_hide_threshold: int = 5) -> List[dict]:
        """
        Comments that have at least one report, with aggregate report count.
        Also returns whether the comment exceeds the auto-hide threshold.
        """
        results = (
            self.db.query(
                models.Comment,
                func.count(models.Report.id).label("report_count"),
            )
            .join(models.Report, models.Report.target_id == models.Comment.id)
            .filter(models.Report.entity_type == "comment")
            .filter(models.Comment.deleted_at == None)  # noqa
            .group_by(models.Comment.id)
            .order_by(func.count(models.Report.id).desc())
            .all()
        )

        return [
            {
                "comment": c,
                "report_count": rc,
                "should_auto_hide": rc >= auto_hide_threshold,
            }
            for c, rc in results
        ]

    def auto_hide_comments(self, threshold: int = 5) -> int:
        """Hide all comments with report_count >= threshold. Returns count updated."""
        count = (
            self.db.query(models.Comment)
            .filter(
                models.Comment.report_count >= threshold,
                models.Comment.is_hidden == False,  # noqa
                models.Comment.deleted_at == None,   # noqa
            )
            .update({"is_hidden": True}, synchronize_session="fetch")
        )
        return count

    # ─── Reports ─────────────────────────────────────────────────

    def list_reports_filtered(
        self,
        status: Optional[str] = None,
        entity_type: Optional[str] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[models.Report]:
        query = self.db.query(models.Report)
        if status:
            query = query.filter(models.Report.status == status)
        if entity_type:
            query = query.filter(models.Report.entity_type == entity_type)
        return query.order_by(models.Report.created_at.desc()).offset(skip).limit(limit).all()

    # ─── Audit Logs ──────────────────────────────────────────────

    def get_audit_logs_filtered(
        self,
        admin_id: Optional[str] = None,
        action: Optional[str] = None,
        target_type: Optional[str] = None,
        from_date: Optional[datetime] = None,
        to_date: Optional[datetime] = None,
        skip: int = 0,
        limit: int = 100,
    ) -> List[models.AuditLog]:
        query = self.db.query(models.AuditLog)

        if admin_id:
            query = query.filter(models.AuditLog.admin_id == admin_id)
        if action:
            query = query.filter(models.AuditLog.action.ilike(f"%{action}%"))
        if target_type:
            query = query.filter(models.AuditLog.target_type == target_type)
        if from_date:
            query = query.filter(models.AuditLog.timestamp >= from_date)
        if to_date:
            query = query.filter(models.AuditLog.timestamp <= to_date)

        return (
            query.order_by(models.AuditLog.timestamp.desc())
            .offset(skip)
            .limit(limit)
            .all()
        )

    # ─── Notifications ───────────────────────────────────────────

    def get_all_user_ids(self) -> List[str]:
        """Return all active user IDs for broadcast notifications."""
        return [
            row[0]
            for row in self.db.query(models.User.id)
            .filter(models.User.status == "active")
            .all()
        ]

    def get_team_follower_ids(self, team_id: str) -> List[str]:
        return [
            row[0]
            for row in self.db.query(models.FavoriteTeam.user_id)
            .filter(models.FavoriteTeam.team_id == team_id)
            .all()
        ]

    def get_league_follower_ids(self, league_id: str) -> List[str]:
        return [
            row[0]
            for row in self.db.query(models.FavoriteLeague.user_id)
            .filter(models.FavoriteLeague.league_id == league_id)
            .all()
        ]
