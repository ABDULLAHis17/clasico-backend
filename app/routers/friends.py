from fastapi import APIRouter, Depends, HTTPException, Request, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_
from typing import List

from ..database import get_db
from ..dependencies import get_current_active_user, limiter
from .. import models
import uuid

router = APIRouter(prefix="/friends", tags=["Friends"])


def _uid():
    return str(uuid.uuid4())


# ── My friends list ──────────────────────────────────────────────
@router.get("/")
@limiter.limit("60/minute")
def get_my_friends(
    request: Request,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    """Return all accepted friends of the current user."""
    rows = db.query(models.Friend).filter(
        or_(
            models.Friend.user_id == me.id,
            models.Friend.friend_user_id == me.id,
        ),
        models.Friend.status == models.FriendshipStatus.accepted,
    ).all()

    result = []
    for row in rows:
        other_id = row.friend_user_id if row.user_id == me.id else row.user_id
        other = db.query(models.User).filter(models.User.id == other_id).first()
        if not other:
            continue
        p = other.profile
        result.append({
            "id": other.id,
            "email": other.email,
            "username": p.username if p else None,
            "display_name": p.display_name if p else None,
            "avatar_url": p.avatar_url if p else None,
            "favorite_team": p.favorite_team_name if p else None,
            "favorite_player": p.favorite_player_name if p else None,
            "favorite_national_team": p.favorite_national_team_name if p else None,
        })
    return result


# ── Pending friend requests ──────────────────────────────────────
@router.get("/requests")
@limiter.limit("60/minute")
def get_friend_requests(
    request: Request,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    """Return pending friend requests sent to me."""
    rows = db.query(models.FriendRequest).filter(
        models.FriendRequest.to_user_id == me.id,
        models.FriendRequest.status == models.FriendRequestStatus.pending,
    ).all()

    result = []
    for row in rows:
        sender = db.query(models.User).filter(models.User.id == row.from_user_id).first()
        if not sender:
            continue
        p = sender.profile
        result.append({
            "request_id": row.id,
            "from_user": {
                "id": sender.id,
                "email": sender.email,
                "username": p.username if p else None,
                "display_name": p.display_name if p else None,
            },
            "created_at": row.created_at,
        })
    return result


# ── Send friend request ──────────────────────────────────────────
@router.post("/request/{target_user_id}")
@limiter.limit("20/minute")
def send_friend_request(
    request: Request,
    target_user_id: str,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    if target_user_id == me.id:
        raise HTTPException(status_code=400, detail="Cannot add yourself.")

    target = db.query(models.User).filter(models.User.id == target_user_id).first()
    if not target:
        raise HTTPException(status_code=404, detail="User not found.")

    # Already friends?
    existing_friendship = db.query(models.Friend).filter(
        or_(
            (models.Friend.user_id == me.id) & (models.Friend.friend_user_id == target_user_id),
            (models.Friend.user_id == target_user_id) & (models.Friend.friend_user_id == me.id),
        )
    ).first()
    if existing_friendship:
        raise HTTPException(status_code=400, detail="Already friends.")

    # Already requested?
    existing_req = db.query(models.FriendRequest).filter(
        models.FriendRequest.from_user_id == me.id,
        models.FriendRequest.to_user_id == target_user_id,
        models.FriendRequest.status == models.FriendRequestStatus.pending,
    ).first()
    if existing_req:
        raise HTTPException(status_code=400, detail="Friend request already sent.")

    freq = models.FriendRequest(
        from_user_id=me.id,
        to_user_id=target_user_id,
        status=models.FriendRequestStatus.pending,
    )
    db.add(freq)
    db.commit()
    return {"status": "ok", "message": "Friend request sent."}


# ── Accept friend request ────────────────────────────────────────
@router.post("/request/{request_id}/accept")
@limiter.limit("30/minute")
def accept_friend_request(
    request: Request,
    request_id: int,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    freq = db.query(models.FriendRequest).filter(
        models.FriendRequest.id == request_id,
        models.FriendRequest.to_user_id == me.id,
        models.FriendRequest.status == models.FriendRequestStatus.pending,
    ).first()
    if not freq:
        raise HTTPException(status_code=404, detail="Friend request not found.")

    freq.status = models.FriendRequestStatus.accepted

    # Create friendship record (bidirectional)
    f1 = models.Friend(
        user_id=freq.from_user_id,
        friend_user_id=me.id,
        status=models.FriendshipStatus.accepted,
    )
    db.add(f1)
    db.commit()
    return {"status": "ok", "message": "Friend request accepted."}


# ── Decline / cancel friend request ────────────────────────────────
@router.post("/request/{request_id}/decline")
@limiter.limit("30/minute")
def decline_friend_request(
    request: Request,
    request_id: int,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    freq = db.query(models.FriendRequest).filter(
        models.FriendRequest.id == request_id,
        models.FriendRequest.to_user_id == me.id,
    ).first()
    if not freq:
        raise HTTPException(status_code=404, detail="Request not found.")
    freq.status = models.FriendRequestStatus.rejected
    db.commit()
    return {"status": "ok", "message": "Request declined."}


# ── Remove friend ────────────────────────────────────────────────
@router.delete("/{friend_user_id}")
@limiter.limit("20/minute")
def remove_friend(
    request: Request,
    friend_user_id: str,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    deleted = db.query(models.Friend).filter(
        or_(
            (models.Friend.user_id == me.id) & (models.Friend.friend_user_id == friend_user_id),
            (models.Friend.user_id == friend_user_id) & (models.Friend.friend_user_id == me.id),
        )
    ).delete(synchronize_session=False)
    db.commit()
    if deleted == 0:
        raise HTTPException(status_code=404, detail="Friend not found.")
    return {"status": "ok"}
