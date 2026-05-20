from fastapi import APIRouter, Depends, HTTPException
from sqlalchemy.orm import Session
from typing import List, Optional

from ..database import get_db
from ..models import League, Team, Player, Stadium
from ..schemas import LeagueSchema

router = APIRouter(prefix="/leagues", tags=["Leagues"])


@router.get("/", response_model=List[LeagueSchema])
def get_leagues(db: Session = Depends(get_db)):
    return db.query(League).all()


@router.get("/{league_id}", response_model=LeagueSchema)
def get_league(league_id: str, db: Session = Depends(get_db)):
    league = db.query(League).filter(League.id == league_id).first()
    if not league:
        raise HTTPException(status_code=404, detail="League not found")
    return league


@router.get("/{league_id}/teams")
def get_league_teams(
    league_id: str,
    search: Optional[str] = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    """Get all teams in a league with their details."""
    league = db.query(League).filter(League.id == league_id).first()
    if not league:
        raise HTTPException(status_code=404, detail="League not found")

    query = db.query(Team).filter(Team.league_id == league_id)
    if search:
        query = query.filter(Team.name.icontains(search))

    teams = query.order_by(Team.name).limit(limit).offset(offset).all()

    result = []
    for t in teams:
        player_count = db.query(Player).filter(Player.team_id == t.id).count()
        stadium = db.query(Stadium).filter(Stadium.id == t.stadium_id).first() if t.stadium_id else None

        result.append({
            "id": t.id,
            "name": t.name,
            "short_name": t.short_name,
            "logo_url": t.logo_url,
            "country": t.country,
            "founded_year": t.founded_year,
            "type": t.type.name if t.type else None,
            "stadium_name": stadium.name if stadium else None,
            "stadium_image": stadium.image_url if stadium else None,
            "squad_size": player_count,
            "league_id": league_id,
            "league_name": league.name,
            "league_logo": league.logo_url,
        })

    return result
