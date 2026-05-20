import random
from fastapi import APIRouter, Depends, Query, HTTPException
from sqlalchemy.orm import Session, joinedload
from typing import List, Optional
from pydantic import BaseModel

from ..database import get_db
from ..models import (
    Match, Lineup, MatchEvent, MatchStatistic, Injury, LeagueStanding,
    League, Team, Player
)
from ..schemas import MatchDetailSchema
from ..seed_mock_matches import seed_mock_matches

router = APIRouter(prefix="/matches", tags=["Matches"])


@router.get("/", response_model=List[MatchDetailSchema])
def get_matches(
    league_id: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    query = db.query(Match).options(
        joinedload(Match.home_team),
        joinedload(Match.away_team),
        joinedload(Match.league),
    )
    if league_id:
        query = query.filter(Match.league_id == league_id)
    return query.order_by(Match.match_date).all()


@router.get("/{match_id}", response_model=MatchDetailSchema)
def get_match(match_id: str, db: Session = Depends(get_db)):
    match = db.query(Match).options(
        joinedload(Match.home_team),
        joinedload(Match.away_team),
        joinedload(Match.league),
    ).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")
    return match


# ── Generate Mock Matches ─────────────────────────────────────

class GenerateResponse(BaseModel):
    status: str
    matches_count: int
    message: str


@router.post("/generate", response_model=GenerateResponse)
def generate_mock_matches(db: Session = Depends(get_db)):
    seed_mock_matches(db)
    count = db.query(Match).count()
    return GenerateResponse(
        status="ok",
        matches_count=count,
        message=f"Generated {count} matches across all leagues"
    )


# ── Match Detail Endpoints ────────────────────────────────────

class LineupResponse(BaseModel):
    match_id: str
    home_team_id: str
    home_team_name: str
    home_formation: str
    home_starting: list[str]
    home_subs: list[str]
    away_team_id: str
    away_team_name: str
    away_formation: str
    away_starting: list[str]
    away_subs: list[str]

    model_config = {"from_attributes": True}


@router.get("/{match_id}/lineup")
def get_match_lineup(match_id: str, db: Session = Depends(get_db)):
    match = db.query(Match).options(
        joinedload(Match.home_team),
        joinedload(Match.away_team),
    ).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    lineups = db.query(Lineup).filter(Lineup.match_id == match_id).all()
    home_lu = next((l for l in lineups if l.team_id == match.home_team_id), None)
    away_lu = next((l for l in lineups if l.team_id == match.away_team_id), None)

    return LineupResponse(
        match_id=match_id,
        home_team_id=match.home_team_id,
        home_team_name=match.home_team.name if match.home_team else 'Home',
        home_formation=home_lu.formation if home_lu else '4-3-3',
        home_starting=home_lu.lineup_json.get('starting', []) if home_lu and home_lu.lineup_json else [],
        home_subs=home_lu.bench_json.get('substitutes', []) if home_lu and home_lu.bench_json else [],
        away_team_id=match.away_team_id,
        away_team_name=match.away_team.name if match.away_team else 'Away',
        away_formation=away_lu.formation if away_lu else '4-3-3',
        away_starting=away_lu.lineup_json.get('starting', []) if away_lu and away_lu.lineup_json else [],
        away_subs=away_lu.bench_json.get('substitutes', []) if away_lu and away_lu.bench_json else [],
    )


class EventItem(BaseModel):
    id: int
    minute: int
    event_type: str
    team_id: str
    player_name: str
    assist_player_name: str | None = None

    model_config = {"from_attributes": True}


@router.get("/{match_id}/events", response_model=List[EventItem])
def get_match_events(match_id: str, db: Session = Depends(get_db)):
    from ..models import MatchEvent as ME, Player
    events = db.query(ME).filter(ME.match_id == match_id).order_by(ME.minute).all()
    result = []
    for e in events:
        result.append(EventItem(
            id=e.id,
            minute=e.minute,
            event_type=e.event_type.value if hasattr(e.event_type, 'value') else str(e.event_type),
            team_id=e.team_id,
            player_name=e.details_json.get('player_name', f'Player {e.player_id[:8]}') if e.details_json else f'Player {e.player_id[:8]}',
            assist_player_name=None,
        ))
    return result


class StatItem(BaseModel):
    team_id: str
    team_name: str | None = None
    possession: int = 0
    shots: int = 0
    shots_on_target: int = 0
    corners: int = 0
    fouls: int = 0
    yellow_cards: int = 0
    red_cards: int = 0
    offsides: int = 0
    passes: int = 0
    pass_accuracy: int = 0

    model_config = {"from_attributes": True}


class MatchStatsResponse(BaseModel):
    match_id: str
    home: StatItem
    away: StatItem


@router.get("/{match_id}/statistics", response_model=MatchStatsResponse)
def get_match_statistics(match_id: str, db: Session = Depends(get_db)):
    match = db.query(Match).options(
        joinedload(Match.home_team),
        joinedload(Match.away_team),
    ).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    stats = db.query(MatchStatistic).filter(MatchStatistic.match_id == match_id).all()
    home_s = next((s for s in stats if s.team_id == match.home_team_id), None)
    away_s = next((s for s in stats if s.team_id == match.away_team_id), None)

    def to_stat_item(s, team, team_name):
        return StatItem(
            team_id=team,
            team_name=team_name,
            possession=s.possession if s else 0,
            shots=s.shots if s else 0,
            shots_on_target=s.shots_on_target if s else 0,
            corners=s.corners if s else 0,
            fouls=s.fouls if s else 0,
            yellow_cards=s.yellow_cards if s else 0,
            red_cards=s.red_cards if s else 0,
            offsides=s.offsides if s else 0,
            passes=s.passes if s else 0,
            pass_accuracy=s.pass_accuracy if s else 0,
        )

    return MatchStatsResponse(
        match_id=match_id,
        home=to_stat_item(home_s, match.home_team_id, match.home_team.name if match.home_team else 'Home'),
        away=to_stat_item(away_s, match.away_team_id, match.away_team.name if match.away_team else 'Away'),
    )


class InjuryItem(BaseModel):
    id: int
    player_name: str
    injury_type: str
    severity: str
    team_name: str
    injury_date: str | None = None
    expected_return: str | None = None

    model_config = {"from_attributes": True}


@router.get("/{match_id}/injuries", response_model=List[InjuryItem])
def get_match_injuries(match_id: str, db: Session = Depends(get_db)):
    match = db.query(Match).options(
        joinedload(Match.home_team),
        joinedload(Match.away_team),
    ).filter(Match.id == match_id).first()
    if not match:
        raise HTTPException(status_code=404, detail="Match not found")

    injuries = db.query(Injury).filter(
        Injury.player_id.in_(
            db.query(Player.id).filter(
                Player.team_id.in_([match.home_team_id, match.away_team_id])
            )
        )
    ).all()

    result = []
    for inj in injuries:
        team_name = 'Unknown'
        player = db.query(Player).filter(Player.id == inj.player_id).first()
        if player and player.team_id:
            t = db.query(Team).filter(Team.id == player.team_id).first()
            if t:
                team_name = t.name
        result.append(InjuryItem(
            id=inj.id,
            player_name=inj.description,
            injury_type=inj.description,
            severity=inj.status.value if hasattr(inj.status, 'value') else str(inj.status),
            team_name=team_name,
            injury_date=str(inj.start_date) if inj.start_date else None,
            expected_return=str(inj.expected_return_date) if inj.expected_return_date else None,
        ))

    return result


class StandingItem(BaseModel):
    position: int
    club_name: str
    club_logo: str | None = None
    matches_played: int = 0
    wins: int = 0
    draws: int = 0
    losses: int = 0
    goals_for: int = 0
    goals_against: int = 0
    goal_difference: int = 0
    points: int = 0
    form: str | None = None

    model_config = {"from_attributes": True}


@router.get("/standings/{league_id}", response_model=List[StandingItem])
def get_league_standings(league_id: str, db: Session = Depends(get_db)):
    standings = db.query(LeagueStanding).filter(
        LeagueStanding.league_id == league_id
    ).order_by(LeagueStanding.position).all()

    result = []
    for s in standings:
        team = db.query(Team).filter(Team.id == s.team_id).first()
        form_chars = ['W', 'W', 'W', 'D', 'D', 'L']
        rng = random.Random(hash(league_id) + s.position)
        result.append(StandingItem(
            position=s.position,
            club_name=team.name if team else 'Unknown',
            club_logo=team.logo_url if team else None,
            matches_played=s.played,
            wins=s.won,
            draws=s.drawn,
            losses=s.lost,
            goals_for=s.goals_for,
            goals_against=s.goals_against,
            goal_difference=s.goals_for - s.goals_against,
            points=s.points,
            form=''.join(rng.choice(form_chars) for _ in range(5)),
        ))

    return result
