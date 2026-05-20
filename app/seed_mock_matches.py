"""
seed_mock_matches.py — Generate 5 rounds of matches per league with full detail data.

Each team plays exactly once per round (round-robin style, circle method).
Match dates are relative to TODAY (today, today+1, ..., today+4).
Generates: Matches, Lineups, MatchEvents, MatchStatistics, Injuries, LeagueStandings.
"""
import random
import uuid
import logging
from datetime import datetime, timedelta, date

from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import SessionLocal
from app.models import (
    League, Team, Player, Match, Lineup, MatchEvent, MatchStatistic,
    Injury, LeagueStanding, MatchStatus, MatchEventType,
    InjuryStatus, LeagueStatistic
)

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

FIRST_NAMES = [
    'Marco', 'Luis', 'Andres', 'Paulo', 'Sergio', 'Kevin', 'Thomas', 'Lucas',
    'David', 'James', 'Carlos', 'Antonio', 'Daniel', 'Jose', 'Angel', 'Rafael',
    'Diego', 'Miguel', 'Alejandro', 'Manuel', 'Pedro', 'Jorge', 'Eduardo',
    'Francisco', 'Juan', 'Pablo', 'Victor', 'Hugo', 'Martin', 'Santiago',
    'Olivier', 'Liam', 'Noah', 'Ethan', 'Mason', 'Luca', 'Matteo', 'Leonardo',
    'Riccardo', 'Francesco', 'Lorenzo', 'Simone', 'Federico', 'Alessandro',
    'Yusuf', 'Mehmet', 'Ali', 'Ahmed', 'Mohamed', 'Hassan',
    'Mats', 'Lars', 'Erik', 'Jonas', 'Sven', 'Jan', 'Max', 'Felix',
]

LAST_NAMES = [
    'Silva', 'Santos', 'Lopez', 'Martinez', 'Rodriguez', 'Garcia',
    'Gonzalez', 'Fernandez', 'Perez', 'Sanchez', 'Ramirez', 'Torres',
    'Rivera', 'Morales', 'Ortiz', 'Cruz', 'Reyes', 'Gutierrez',
    'Molina', 'Diaz', 'Moreno', 'Alvarez', 'Romero', 'Navarro',
    'Russo', 'Ferrari', 'Bianchi', 'Romano', 'Gallo', 'Costa',
    'Fontana', 'Conti', 'Esposito', 'Ricci', 'Bruno', 'Barbieri',
    'Marchetti', 'Rinaldi', 'Caruso', 'Amato', 'Moretti', 'Gatti',
    'Berg', 'Andersen', 'Johansson', 'Lindberg', 'Nilsson', 'Eriksson',
    'Karlsson', 'Gustavsson', 'Lundqvist', 'Wallin',
    'Petersen', 'Christensen', 'Jensen', 'Sorensen', 'Rasmussen',
    'Muller', 'Schmidt', 'Weber', 'Wagner', 'Becker', 'Hoffman',
]

POSITIONS = ['GK', 'CB', 'CB', 'LB', 'RB', 'CDM', 'CM', 'CM', 'LW', 'RW', 'ST']
INJURY_NAMES = [
    'Hamstring Strain', 'Ankle Sprain', 'ACL Tear', 'Groin Pull',
    'Calf Strain', 'Knee Injury', 'Shoulder Dislocation', 'Concussion',
    'Thigh Strain', 'Back Spasm', 'Hip Flexor', 'Quad Strain',
    'Meniscus Tear', 'Achilles Tendonitis', 'Rib Fracture',
]
INJURY_SEVERITIES = ['minor', 'moderate', 'severe']
FORMATIONS = ['4-3-3', '4-4-2', '4-2-3-1', '3-5-2', '3-4-3', '4-1-4-1']


def _rng_for(match_id: str, seed_offset: int = 0) -> random.Random:
    return random.Random(hash(match_id) + seed_offset)


def _generate_player_name(rng: random.Random) -> str:
    return f"{rng.choice(FIRST_NAMES)} {rng.choice(LAST_NAMES)}"


def clean_mock_match_data(db: Session):
    logger.info("Cleaning old match mock data...")
    db.execute(text("SET FOREIGN_KEY_CHECKS = 0"))
    for table in ['lineups', 'match_events', 'match_statistics',
                  'injuries', 'league_standings', 'league_statistics', 'matches']:
        try:
            db.execute(text(f"DELETE FROM {table}"))
        except Exception:
            pass
    db.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
    db.commit()
    logger.info("  Old match data cleaned")


def seed_mock_matches(db: Session | None = None):
    should_close = False
    if db is None:
        db = SessionLocal()
        should_close = True

    try:
        # Check if matches already exist
        existing = db.query(Match).count()
        if existing > 0:
            logger.info(f"  {existing} matches already exist, skipping.")
            return

        clean_mock_match_data(db)

        leagues = db.query(League).all()
        logger.info(f"Generating matches for {len(leagues)} leagues...")

        today = date.today()

        for league in leagues:
            teams = db.query(Team).filter(Team.league_id == league.id).all()
            if len(teams) < 2:
                continue

            _generate_league_matches(db, league, teams, today)

        # Generate standings for all leagues
        leagues = db.query(League).all()
        for league in leagues:
            _generate_standings(db, league)

        db.commit()
        total_matches = db.query(Match).count()
        total_events = db.query(MatchEvent).count()
        total_lineups = db.query(Lineup).count()
        logger.info(f"Generated: {total_matches} matches, {total_events} events, {total_lineups} lineups")

    except Exception as e:
        db.rollback()
        logger.error(f"Failed to seed matches: {e}")
        raise
    finally:
        if should_close:
            db.close()


def _generate_league_matches(db: Session, league: League, teams: list[Team], start_date: date):
    """Generate 5 rounds of matches using circle method."""
    # Create a working list; if odd, pad with None (BYE)
    team_list = list(teams)
    rng = random.Random(hash(league.id))

    if len(team_list) % 2 == 1:
        team_list.append(None)  # BYE

    n = len(team_list)
    num_rounds = 5

    for round_idx in range(num_rounds):
        match_date = start_date + timedelta(days=round_idx)

        for i in range(n // 2):
            home = team_list[i]
            away = team_list[n - 1 - i]

            if home is None or away is None:
                continue  # BYE match, skip

            is_played = round_idx < 4  # First 4 rounds are played, 5th is upcoming
            home_score = None
            away_score = None
            status = MatchStatus.scheduled

            if is_played:
                home_score = rng.randint(0, 4)
                away_score = rng.randint(0, 4)
                status = MatchStatus.finished

            match_id = f"mock_{league.id}_{round_idx}_{i}"
            match_time = datetime.combine(match_date, datetime.min.time()) + timedelta(
                hours=rng.randint(12, 22),
                minutes=rng.choice([0, 15, 30, 45])
            )

            match = Match(
                id=match_id,
                league_id=league.id,
                home_team_id=home.id,
                away_team_id=away.id,
                home_score=home_score or 0,
                away_score=away_score or 0,
                match_date=match_time,
                status=status,
                round=f"Round {round_idx + 1}",
            )
            db.add(match)
            db.flush()

            if is_played:
                _generate_match_detail(db, match, home, away, home_score or 0, away_score or 0, rng)

        # Rotate: keep first fixed, rotate rest clockwise
        if n >= 3:
            fixed = [team_list[0]]
            rotating = team_list[1:]
            rotating = [rotating[-1]] + rotating[:-1]
            team_list = fixed + rotating


def _generate_match_detail(db: Session, match: Match, home: Team, away: Team,
                           home_score: int, away_score: int, rng: random.Random):
    """Generate events, lineup, statistics for a match."""
    seed = hash(match.id)
    mrng = random.Random(seed)

    # ── Lineup ──
    formation = mrng.choice(FORMATIONS)
    home_players = [_generate_player_name(mrng) for _ in range(11)]
    home_subs = [_generate_player_name(mrng) for _ in range(5)]
    away_players = [_generate_player_name(mrng) for _ in range(11)]
    away_subs = [_generate_player_name(mrng) for _ in range(5)]

    db.add(Lineup(
        match_id=match.id, team_id=home.id, formation=formation,
        lineup_json={"starting": home_players, "positions": POSITIONS[:11]},
        bench_json={"substitutes": home_subs},
    ))
    db.add(Lineup(
        match_id=match.id, team_id=away.id, formation=formation,
        lineup_json={"starting": away_players, "positions": POSITIONS[:11]},
        bench_json={"substitutes": away_subs},
    ))

    # ── Events ──
    event_id = 0
    used_minutes = set()
    event_types = []

    for _ in range(home_score):
        minute = _unique_minute(mrng, used_minutes)
        event_types.append((minute, 'goal', 'home'))
    for _ in range(away_score):
        minute = _unique_minute(mrng, used_minutes)
        event_types.append((minute, 'goal', 'away'))

    num_yellow = mrng.randint(0, 5)
    for _ in range(num_yellow):
        minute = _unique_minute(mrng, used_minutes)
        event_types.append((minute, 'yellow_card', mrng.choice(['home', 'away'])))

    if mrng.random() < 0.15:
        minute = _unique_minute(mrng, used_minutes)
        event_types.append((minute, 'red_card', mrng.choice(['home', 'away'])))

    num_subs = mrng.randint(1, 5)
    for _ in range(num_subs):
        minute = _unique_minute(mrng, used_minutes)
        event_types.append((minute, 'substitution', mrng.choice(['home', 'away'])))

    event_types.sort(key=lambda x: x[0])

    for minute, ev_type, team_side in event_types:
        team_id = home.id if team_side == 'home' else away.id
        player_name = _generate_player_name(mrng)

        db.add(MatchEvent(
            match_id=match.id, minute=minute, event_type=MatchEventType(ev_type),
            team_id=team_id, player_id=_get_any_player(db, team_id),
            assist_player_id=_get_any_player(db, team_id) if ev_type == 'goal' and mrng.random() < 0.7 else None,
            details_json={'player_name': player_name} if ev_type == 'substitution' else None,
        ))

    # ── Statistics ──
    home_poss = 35 + mrng.randint(0, 30)
    home_shots = home_score + mrng.randint(0, 12)
    away_shots = away_score + mrng.randint(0, 12)

    for team_id, side, score in [(home.id, 'home', home_score), (away.id, 'away', away_score)]:
        poss = home_poss if side == 'home' else 100 - home_poss
        shots = home_shots if side == 'home' else away_shots
        db.add(MatchStatistic(
            match_id=match.id, team_id=team_id,
            possession=poss, shots=shots,
            shots_on_target=score + mrng.randint(0, 4),
            corners=mrng.randint(0, 10), fouls=5 + mrng.randint(0, 15),
            yellow_cards=mrng.randint(0, 4), red_cards=mrng.randint(0, 2),
            offsides=mrng.randint(0, 5), passes=200 + mrng.randint(0, 400),
            pass_accuracy=65 + mrng.randint(0, 30),
        ))

    # ── Injuries ──
    num_injuries = mrng.randint(0, 3)
    for i in range(num_injuries):
        player_name = _generate_player_name(mrng)
        severity = mrng.choice(INJURY_SEVERITIES)
        days_out = {'minor': 3 + mrng.randint(0, 12), 'moderate': 15 + mrng.randint(0, 30), 'severe': 60 + mrng.randint(0, 120)}[severity]
        inj_date = match.match_date.date() - timedelta(days=mrng.randint(0, 5))

        db.add(Injury(
            player_id=_get_any_player(db, mrng.choice([home.id, away.id])) or '',
            description=player_name,
            start_date=inj_date,
            expected_return_date=inj_date + timedelta(days=days_out),
            status=InjuryStatus.active,
        ))


def _unique_minute(rng: random.Random, used: set) -> int:
    for _ in range(100):
        m = 1 + rng.randint(0, 90)
        if m not in used:
            used.add(m)
            return m
    m = max(used) + 1 if used else 1
    used.add(m)
    return m


def _get_any_player(db: Session, team_id: str) -> str | None:
    player = db.query(Player).filter(Player.team_id == team_id).first()
    return player.id if player else str(uuid.uuid4())


def _generate_standings(db: Session, league: League):
    """Generate standings for a league."""
    rng = random.Random(hash(league.id) + 999)
    teams = db.query(Team).filter(Team.league_id == league.id).all()

    entries = []
    for team in teams:
        mp = 5 + rng.randint(0, 30)
        gf = rng.randint(10, 60)
        ga = rng.randint(5, 50)
        pts = max(0, mp * 2 + rng.randint(-20, 40))
        pts = min(pts, mp * 3)
        entries.append({'team': team, 'mp': mp, 'gf': gf, 'ga': ga, 'pts': pts})

    entries.sort(key=lambda e: (-e['pts'], -(e['gf'] - e['ga']), -e['gf']))

    form_chars = ['W', 'W', 'W', 'W', 'D', 'D', 'L', 'L', 'L']
    for pos, entry in enumerate(entries):
        team = entry['team']
        pts = entry['pts']
        mp = entry['mp']
        gf = entry['gf']
        ga = entry['ga']
        w = min(max(0, pts // 3), mp)
        d = pts - w * 3
        l = mp - w - d
        form = ''.join(rng.choice(form_chars) for _ in range(5))

        existing = db.query(LeagueStanding).filter(
            LeagueStanding.league_id == league.id,
            LeagueStanding.team_id == team.id
        ).first()
        if existing:
            existing.position = pos + 1
            existing.played = mp
            existing.won = w
            existing.drawn = d
            existing.lost = l
            existing.goals_for = gf
            existing.goals_against = ga
            existing.points = pts
        else:
            db.add(LeagueStanding(
                league_id=league.id, team_id=team.id,
                position=pos + 1, played=mp, won=w, drawn=d, lost=l,
                goals_for=gf, goals_against=ga, points=pts,
            ))


if __name__ == '__main__':
    seed_mock_matches()
