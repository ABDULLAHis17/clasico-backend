from fastapi import APIRouter, Depends, HTTPException, status, Query
from sqlalchemy.orm import Session
from sqlalchemy import or_

from .. import schemas, models
from ..database import get_db
from ..dependencies import get_current_active_user

router = APIRouter(prefix="/users", tags=["Users"])


@router.get("/me", response_model=schemas.UserMeSchema)
def get_my_profile(db: Session = Depends(get_db), user: models.User = Depends(get_current_active_user)):
    fav_teams = db.query(models.FavoriteTeam).filter(models.FavoriteTeam.user_id == user.id).count() if hasattr(models, 'FavoriteTeam') else 0
    fav_players = db.query(models.FavoritePlayer).filter(models.FavoritePlayer.user_id == user.id).count() if hasattr(models, 'FavoritePlayer') else 0
    fav_leagues = db.query(models.FavoriteLeague).filter(models.FavoriteLeague.user_id == user.id).count() if hasattr(models, 'FavoriteLeague') else 0

    profile = user.profile
    return {
        "id": user.id,
        "email": user.email,
        "status": user.status,
        "username": profile.username if profile else None,
        "display_name": profile.display_name if profile else None,
        "phone_number": profile.phone_number if profile else None,
        "avatar_url": profile.avatar_url if profile else None,
        "favorite_teams": fav_teams,
        "favorite_players": fav_players,
        "favorite_leagues": fav_leagues,
        "created_at": user.created_at,
    }


@router.put("/me/profile")
def update_my_profile(
    data: schemas.UserProfileUpdateSchema,
    db: Session = Depends(get_db),
    user: models.User = Depends(get_current_active_user),
):
    profile = user.profile
    if not profile:
        profile = models.UserProfile(user_id=user.id)
        db.add(profile)

    if data.username is not None:
        existing = db.query(models.UserProfile).filter(
            models.UserProfile.username == data.username,
            models.UserProfile.user_id != user.id
        ).first()
        if existing:
            raise HTTPException(status_code=400, detail="Username already taken")
        profile.username = data.username

    if data.phone_number is not None:
        profile.phone_number = data.phone_number
    if data.display_name is not None:
        profile.display_name = data.display_name

    if data.favorite_player is not None:
        profile.favorite_player_name = data.favorite_player
    if data.favorite_team is not None:
        profile.favorite_team_name = data.favorite_team
    if data.favorite_national_team is not None:
        profile.favorite_national_team_name = data.favorite_national_team
    if data.favorite_league is not None:
        profile.favorite_league_name = data.favorite_league
    
    db.commit()
    db.refresh(profile)
    return {"status": "ok", "username": profile.username, "display_name": profile.display_name}


@router.get("/search", response_model=list[schemas.UserSearchResultSchema])
def search_users(
    q: str = Query(..., min_length=1),
    db: Session = Depends(get_db),
    _: models.User = Depends(get_current_active_user),
):
    results = (
        db.query(models.User)
        .outerjoin(models.UserProfile)
        .filter(
            or_(
                models.UserProfile.username.ilike(f"%{q}%"),
                models.UserProfile.display_name.ilike(f"%{q}%"),
                models.User.email.ilike(f"%{q}%"),
            )
        )
        .limit(20)
        .all()
    )
    return [
        {
            "id": u.id,
            "email": u.email,
            "username": u.profile.username if u.profile else None,
            "display_name": u.profile.display_name if u.profile else None,
            "avatar_url": u.profile.avatar_url if u.profile else None,
        }
        for u in results
    ]
