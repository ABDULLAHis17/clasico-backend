from fastapi import APIRouter
from . import dashboard, users, comments, reports, notifications, audit_logs, feedback

router = APIRouter(prefix="/admin", tags=["Admin"])

router.include_router(dashboard.router)
router.include_router(users.router)
router.include_router(comments.router)
router.include_router(reports.router)
router.include_router(notifications.router)
router.include_router(audit_logs.router)
router.include_router(feedback.router)
