from fastapi import APIRouter, Depends, HTTPException, Request
from sqlalchemy.orm import Session
from sqlalchemy import and_, or_
from typing import Optional
from datetime import datetime
import uuid

from ..database import get_db
from ..dependencies import get_current_active_user, limiter
from .. import models

router = APIRouter(prefix="/chat", tags=["Chat"])


def _gen_id():
    return str(uuid.uuid4())


# ─────────────────────────────────────────
# Start or get existing direct conversation
# ─────────────────────────────────────────
@router.post("/start")
@limiter.limit("30/minute")
def start_conversation(
    request: Request,
    other_user_id: str,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    """Start a direct (1-on-1) conversation or return existing one."""
    if other_user_id == me.id:
        raise HTTPException(status_code=400, detail="Cannot start a conversation with yourself.")

    # Check the other user exists
    other = db.query(models.User).filter(models.User.id == other_user_id).first()
    if not other:
        raise HTTPException(status_code=404, detail="User not found.")

    # Find existing direct conversation between the two users
    my_convs = (
        db.query(models.ConversationParticipant.conversation_id)
        .filter(models.ConversationParticipant.user_id == me.id)
        .subquery()
    )
    their_convs = (
        db.query(models.ConversationParticipant.conversation_id)
        .filter(models.ConversationParticipant.user_id == other_user_id)
        .subquery()
    )
    shared_conv = (
        db.query(models.Conversation)
        .filter(
            models.Conversation.id.in_(my_convs),
            models.Conversation.id.in_(their_convs),
            models.Conversation.is_group == False,  # noqa
        )
        .first()
    )

    if shared_conv:
        conv_id = shared_conv.id
    else:
        # Create new conversation
        conv_id = _gen_id()
        conv = models.Conversation(
            id=conv_id,
            is_group=False,
            created_by_user_id=me.id,
        )
        db.add(conv)
        db.add(models.ConversationParticipant(conversation_id=conv_id, user_id=me.id))
        db.add(models.ConversationParticipant(conversation_id=conv_id, user_id=other_user_id))
        db.commit()

    # Build profile info for the other user
    other_profile = other.profile
    return {
        "conversation_id": conv_id,
        "other_user": {
            "id": other.id,
            "email": other.email,
            "display_name": other_profile.display_name if other_profile else None,
            "username": other_profile.username if other_profile else None,
            "avatar_url": other_profile.avatar_url if other_profile else None,
        },
    }


# ─────────────────────────────────────────
# List my conversations
# ─────────────────────────────────────────
@router.get("/conversations")
@limiter.limit("60/minute")
def list_conversations(
    request: Request,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    """List all conversations the current user participates in."""
    participants = (
        db.query(models.ConversationParticipant)
        .filter(models.ConversationParticipant.user_id == me.id)
        .all()
    )

    result = []
    for p in participants:
        conv = db.query(models.Conversation).filter(models.Conversation.id == p.conversation_id).first()
        if not conv:
            continue

        # Get the other participants
        others = (
            db.query(models.ConversationParticipant)
            .filter(
                models.ConversationParticipant.conversation_id == conv.id,
                models.ConversationParticipant.user_id != me.id,
            )
            .all()
        )

        other_users = []
        for op in others:
            u = db.query(models.User).filter(models.User.id == op.user_id).first()
            if u:
                prof = u.profile
                other_users.append({
                    "id": u.id,
                    "display_name": prof.display_name if prof else u.email,
                    "username": prof.username if prof else None,
                    "avatar_url": prof.avatar_url if prof else None,
                })

        # Get last message
        last_msg = (
            db.query(models.Message)
            .filter(
                models.Message.conversation_id == conv.id,
                models.Message.deleted_at == None,  # noqa
            )
            .order_by(models.Message.created_at.desc())
            .first()
        )

        result.append({
            "id": conv.id,
            "is_group": conv.is_group,
            "title": conv.title,
            "created_at": conv.created_at,
            "participants": other_users,
            "last_message": {
                "content": last_msg.content,
                "created_at": last_msg.created_at,
                "sender_id": last_msg.sender_user_id,
            } if last_msg else None,
        })

    # Sort by last message time
    result.sort(key=lambda x: x["last_message"]["created_at"] if x["last_message"] else x["created_at"], reverse=True)
    return result


# ─────────────────────────────────────────
# Get messages in a conversation
# ─────────────────────────────────────────
@router.get("/conversations/{conv_id}/messages")
@limiter.limit("120/minute")
def get_messages(
    request: Request,
    conv_id: str,
    since: Optional[str] = None,
    limit: int = 50,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    """Get messages for a conversation. Optional `since` (ISO datetime) for polling."""
    # Verify participation
    participant = db.query(models.ConversationParticipant).filter(
        models.ConversationParticipant.conversation_id == conv_id,
        models.ConversationParticipant.user_id == me.id,
    ).first()
    if not participant:
        raise HTTPException(status_code=403, detail="Not a participant in this conversation.")

    query = db.query(models.Message).filter(
        models.Message.conversation_id == conv_id,
        models.Message.deleted_at == None,  # noqa
    )

    if since:
        try:
            since_dt = datetime.fromisoformat(since)
            query = query.filter(models.Message.created_at > since_dt)
        except ValueError:
            pass

    messages = query.order_by(models.Message.created_at.asc()).limit(limit).all()

    result = []
    for msg in messages:
        sender = db.query(models.User).filter(models.User.id == msg.sender_user_id).first()
        sender_name = None
        sender_username = None
        if sender and sender.profile:
            sender_name = sender.profile.display_name
            sender_username = sender.profile.username
        elif sender:
            sender_name = sender.email

        result.append({
            "id": msg.id,
            "conversation_id": msg.conversation_id,
            "sender_id": msg.sender_user_id,
            "sender_name": sender_name,
            "sender_username": sender_username,
            "content": msg.content,
            "type": msg.type.value if msg.type else "text",
            "created_at": msg.created_at.isoformat(),
            "is_mine": msg.sender_user_id == me.id,
        })

    return result


# ─────────────────────────────────────────
# Send a message
# ─────────────────────────────────────────
@router.post("/conversations/{conv_id}/messages")
@limiter.limit("60/minute")
def send_message(
    request: Request,
    conv_id: str,
    content: str,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    """Send a text message to a conversation."""
    if not content or not content.strip():
        raise HTTPException(status_code=400, detail="Message content cannot be empty.")

    # Verify participation
    participant = db.query(models.ConversationParticipant).filter(
        models.ConversationParticipant.conversation_id == conv_id,
        models.ConversationParticipant.user_id == me.id,
    ).first()
    if not participant:
        raise HTTPException(status_code=403, detail="Not a participant in this conversation.")

    msg = models.Message(
        id=_gen_id(),
        conversation_id=conv_id,
        sender_user_id=me.id,
        type=models.MessageType.text,
        content=content.strip(),
    )
    db.add(msg)
    db.commit()
    db.refresh(msg)

    return {
        "id": msg.id,
        "conversation_id": msg.conversation_id,
        "sender_id": msg.sender_user_id,
        "content": msg.content,
        "type": "text",
        "created_at": msg.created_at.isoformat(),
        "is_mine": True,
    }


# ─────────────────────────────────────────
# Delete a message (soft delete)
# ─────────────────────────────────────────
@router.delete("/messages/{msg_id}")
@limiter.limit("30/minute")
def delete_message(
    request: Request,
    msg_id: str,
    db: Session = Depends(get_db),
    me: models.User = Depends(get_current_active_user),
):
    msg = db.query(models.Message).filter(models.Message.id == msg_id).first()
    if not msg:
        raise HTTPException(status_code=404, detail="Message not found.")
    if msg.sender_user_id != me.id:
        raise HTTPException(status_code=403, detail="Cannot delete another user's message.")

    msg.deleted_at = datetime.utcnow()
    db.commit()
    return {"status": "ok"}
