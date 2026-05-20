"""
seed_v2.py — Clean, complete data import from JSON datasets into MySQL.

Imports: Leagues, Teams, Stadiums, Coaches, Players with real photo URLs,
ratings, positions, shirt numbers, nationalities, heights, weights, etc.

Strategy:
1. Wipe old mock data (seed.py t-prefix teams, emoji photo players)
2. Import all 16 leagues from leagues.json + league_details.json
3. Import all teams from team_details.json with proper league linkage
4. Import stadiums from team_details.json
5. Import coaches from team_details.json (with photo URLs)
6. Import all players from players.json with full data + CDN photo URLs
"""
import json
import uuid
import re
import logging
import os

logging.basicConfig(level=logging.INFO, format="%(levelname)s: %(message)s")
logger = logging.getLogger(__name__)

from sqlalchemy.orm import Session
from sqlalchemy import text
from app.database import SessionLocal
from app.models import (
    League, Team, Player, Stadium, Coach, Match, News, MatchStatus,
    Role, User, UserProfile
)


# ─── Helpers ────────────────────────────────────────────────────────

def ext(val, field='text'):
    if not val:
        return None
    if isinstance(val, dict):
        return (val.get(field) or '').strip() or None
    return str(val).strip() or None


def extnum(val):
    if not val:
        return None
    s = ext(val) or str(val)
    m = re.search(r'\d+', s)
    return int(m.group()) if m else None


def extract_id(link, key):
    if not link or f'{key}=' not in link:
        return None
    return link.split(f'{key}=')[-1].split('&')[0].strip()


DATA_DIR = os.path.join(os.path.dirname(__file__), 'data')


def load_json(filename):
    path = os.path.join(DATA_DIR, filename)
    if not os.path.exists(path):
        logger.warning(f"  File not found: {path}")
        return []
    with open(path, encoding='utf-8') as f:
        return json.load(f)


# ─── Main seed function ─────────────────────────────────────────────

def seed_v2():
    db = SessionLocal()
    try:
        _ensure_roles_and_admin(db)

        real_player_count = db.query(Player).filter(
            Player.photo_url.like('http%')
        ).count()
        real_team_count = db.query(Team).filter(
            Team.logo_url.like('http%'), ~Team.id.like('t%')
        ).count()

        if real_team_count > 50 and real_player_count > 500:
            logger.info("Real data already seeded, skipping.")
            return

        logger.info("Starting clean data import from JSON datasets...")
        _clean_mock_data(db)

        leagues_json = load_json('leagues.json')
        league_details_json = load_json('league_details.json')
        team_details_json = load_json('team_details.json')
        players_json = load_json('players.json')

        if not team_details_json or not players_json:
            logger.error("Required dataset files missing, aborting.")
            return

        logger.info(f"  Loaded {len(leagues_json)} leagues, "
                     f"{len(team_details_json)} teams, "
                     f"{len(players_json)} players")

        league_idx_to_id = _import_leagues(db, leagues_json, league_details_json)
        team_idx_to_id, team_clubid_to_id = _import_teams_stadiums_coaches(
            db, team_details_json, league_idx_to_id
        )
        _import_players(db, players_json, team_details_json, team_idx_to_id)
        _verify(db)

        db.commit()
        logger.info("Data import completed successfully!")

    except Exception as e:
        db.rollback()
        logger.error(f"Import failed: {e}")
        raise
    finally:
        db.close()


# ─── Sub-functions ──────────────────────────────────────────────────

def _ensure_roles_and_admin(db):
    roles = [
        Role(name="user", description="Default user role"),
        Role(name="moderator", description="Can moderate content"),
        Role(name="admin", description="Full system access"),
    ]
    for r in roles:
        if not db.query(Role).filter(Role.name == r.name).first():
            db.add(r)
    db.flush()

    from app.auth import get_password_hash
    admin_email = "admin@clasico.com"
    if not db.query(User).filter(User.email == admin_email).first():
        admin = User(
            id=admin_email, email=admin_email,
            hashed_password=get_password_hash("admin123"), status="active"
        )
        db.add(admin)
        db.flush()
        db.add(UserProfile(user_id=admin.id, display_name="System Admin"))
        admin_role = db.query(Role).filter(Role.name == "admin").first()
        if admin_role:
            admin.roles.append(admin_role)
    db.commit()


def _clean_mock_data(db):
    logger.info("Cleaning old mock data...")
    # Disable FK checks to allow clean deletion in any order
    db.execute(text("SET FOREIGN_KEY_CHECKS = 0"))

    # Delete all football-related data (mock + broken imports)
    for table in ['players', 'coaches', 'matches', 'teams', 'stadiums', 'leagues',
                  'seasons', 'transfers', 'lineups', 'match_events', 'match_statistics',
                  'injuries', 'news', 'league_standings', 'league_statistics',
                  'favorite_matches', 'favorite_teams', 'favorite_players', 'favorite_leagues']:
        try:
            db.execute(text(f"DELETE FROM {table}"))
        except Exception:
            pass  # Table may not exist on first run

    db.execute(text("SET FOREIGN_KEY_CHECKS = 1"))
    db.commit()
    logger.info("  Mock data cleaned")


def _import_leagues(db, leagues_json, league_details_json):
    logger.info("Importing Leagues...")
    league_idx_to_id = {}

    for idx, league in enumerate(leagues_json):
        link = league.get('link', '')
        league_id = extract_id(link, 'leagueid') or str(uuid.uuid4())
        name = ext(league.get('name'))
        if not name:
            continue

        country = None
        if idx < len(league_details_json):
            country = ext(league_details_json[idx].get('\u0628\u0644\u062f:'))

        logo_url = f'https://cdn.soccerwiki.org/images/logos/leagues/{league_id}.png'

        if not db.query(League).filter(League.id == league_id).first():
            db.add(League(id=league_id, name=name, country=country, logo_url=logo_url))
            db.flush()

        league_idx_to_id[idx] = league_id

    db.commit()
    logger.info(f"  Imported {len(league_idx_to_id)} leagues")
    return league_idx_to_id


def _import_teams_stadiums_coaches(db, team_details_json, league_idx_to_id):
    logger.info("Importing Stadiums, Teams, and Coaches...")
    team_idx_to_id = {}
    team_clubid_to_id = {}
    stadium_name_to_id = {}

    for idx, td in enumerate(team_details_json):
        league_id = league_idx_to_id.get(td.get('league_index'))

        # ── Stadium ──
        stadium_name = ext(td.get('\u0645\u0644\u0639\u0628:'))
        stadium_link = ''
        raw_stadium = td.get('\u0645\u0644\u0639\u0628:')
        if isinstance(raw_stadium, dict):
            stadium_link = raw_stadium.get('link', '') or ''

        stadium_id = None
        if stadium_name:
            if stadium_name in stadium_name_to_id:
                stadium_id = stadium_name_to_id[stadium_name]
            else:
                stadiumdid = extract_id(stadium_link, 'stadiumdid')
                stadium_image = f'https://cdn.soccerwiki.org/images/stadium/{stadiumdid}.jpg' if stadiumdid else None
                db_stadium = db.query(Stadium).filter(Stadium.name == stadium_name).first()
                if not db_stadium:
                    stadium_city = ext(td.get('\u0627\u0644\u0645\u0648\u0642\u0639:'))
                    db_stadium = Stadium(
                        id=stadiumdid or str(uuid.uuid4()),
                        name=stadium_name,
                        city=stadium_city,
                        country=ext(td.get('\u0628\u0644\u062f:')),
                        image_url=stadium_image,
                    )
                    db.add(db_stadium)
                    db.flush()
                stadium_id = db_stadium.id
                stadium_name_to_id[stadium_name] = stadium_id

        # ── Team ──
        team_image = td.get('image', '')
        clubid = None
        if team_image and '/clubs/' in team_image:
            m = re.search(r'/clubs/(\d+)', team_image)
            if m:
                clubid = m.group(1)

        team_id = clubid or str(uuid.uuid4())

        team_name = ext(td.get('\u0625\u0633\u0645 \u0645\u062a\u0648\u0633\u0637:')) or ext(td.get('\u0627\u0644\u0644\u0642\u0628:'))
        short_name = ext(td.get('\u0627\u0644\u0625\u0633\u0645 \u0627\u0644\u0645\u062e\u062a\u0635\u0631:'))
        founded_year = extnum(td.get('\u0633\u0646\u0629 \u0627\u0644\u062a\u0623\u0633\u064a\u0633:'))
        country = ext(td.get('\u0628\u0644\u062f:'))

        logo_url = team_image
        if logo_url and 'spacer.gif' in logo_url:
            logo_url = f'https://cdn.soccerwiki.org/images/logos/clubs/{clubid}.png' if clubid else None

        if not db.query(Team).filter(Team.id == team_id).first():
            db.add(Team(
                id=team_id, name=team_name, short_name=short_name,
                founded_year=founded_year, country=country, logo_url=logo_url,
                league_id=league_id, stadium_id=stadium_id, type='club',
            ))
            db.flush()

        team_idx_to_id[idx] = team_id
        if clubid:
            team_clubid_to_id[clubid] = team_id

        # ── Coach ──
        coach_data = td.get('coach')
        if coach_data:
            coach_name = ext(coach_data.get('\u0628\u0644\u062f'))
            coach_image = coach_data.get('image', '')
            coach_link = ''
            raw_coach_country = coach_data.get('\u0628\u0644\u062f')
            if isinstance(raw_coach_country, dict):
                coach_link = raw_coach_country.get('link', '') or ''

            mid = extract_id(coach_link, 'mid')
            if coach_name:
                coach_id = mid or str(uuid.uuid4())
                photo_url = None
                if coach_image and 'missing_manager' not in coach_image:
                    photo_url = coach_image
                elif mid:
                    photo_url = f'https://cdn.soccerwiki.org/images/manager/{mid}.png'

                if not db.query(Coach).filter(Coach.id == coach_id).first():
                    db.add(Coach(
                        id=coach_id, team_id=team_id,
                        name=coach_name, photo_url=photo_url,
                    ))

        if idx % 100 == 0 and idx > 0:
            db.commit()
            logger.info(f"  Progress: {idx} teams...")

    db.commit()
    logger.info(f"  Imported {len(team_idx_to_id)} teams with stadiums and coaches")
    return team_idx_to_id, team_clubid_to_id


def _import_players(db, players_json, team_details_json, team_idx_to_id):
    logger.info("Importing Players...")

    # Build per-team player name → pid mapping from team_details for CDN photo URLs
    # team_details has short display names, players.json has full names
    # So we build multiple lookup strategies per team
    import unicodedata

    def _normalize(name):
        nf = unicodedata.normalize('NFKD', name.lower())
        stripped = ''.join(c for c in nf if not unicodedata.combining(c))
        return ''.join(c for c in stripped if c.isalnum() or c == ' ').strip()

    # Global lookup: normalized name → pid (with multiple variants)
    global_name_to_pid = {}
    # Also build per-team lookup for constrained matching
    team_player_names = {}  # team_idx → [{norm, pid, parts}, ...]
    # Last name index for better disambiguation
    global_last_name = {}  # last_name → [(pid, full_norm, td_idx)]

    for td_idx, td in enumerate(team_details_json):
        team_list = []
        for p in td.get('players', []):
            name = (p.get('name') or '').strip()
            link = p.get('link', '')
            pid = extract_id(link, 'pid')
            if name and pid:
                norm = _normalize(name)
                global_name_to_pid[norm] = pid
                # All individual parts as keys (handles "Braut Håland" → "haland")
                parts = norm.split()
                if len(parts) > 1:
                    if parts[-1] not in global_name_to_pid:
                        global_name_to_pid[parts[-1]] = pid
                    # Track last name → pid with context for disambiguation
                    if parts[-1] not in global_last_name:
                        global_last_name[parts[-1]] = []
                    global_last_name[parts[-1]].append((pid, norm, td_idx))
                    # Also first name only (for "Kylian" → Mbappé)
                    if parts[0] not in global_name_to_pid:
                        global_name_to_pid[parts[0]] = pid
                team_list.append({'norm': norm, 'pid': pid, 'parts': parts})
        team_player_names[td_idx] = team_list

    # Manual PID overrides for players whose names match incorrectly via fuzzy logic
    _PID_OVERRIDES = {
        'cristiano ronaldo dos santos aveiro': '1131',
        'vitor machado ferreira': '115519',
        'vinicius jose paixao de oliveira junior': '90068',
        'olavio vieira dos santos junior': '94644',
        'lucas francois bernard hernandez pi': '84923',
        'bernardo mota veiga de carvalho e silva': '84660',
        'gabriel dos santos magalhaes': '89344',
        'gabriel fernando de jesus': '80266',
        'daniel carvajal ramos': '46587',
        'rodrygo silva de goes': '93823',
        'pedro gonzalez lopez': '102243',
        'ronald federico araujo da silva': '94977',
        'alejandro balde martinez': '110049',
        'javier puado diaz': '99638',
        'gerard martin langreo': '138048',
        'carlos romero serrano': '130178',
        'pol lozano vizuete': '101455',
        'leandro daniel cabrera sasia': '37510',
        'fernando calero villa': '88838',
        'miguel angel rubio lestan': '101661',
        'jose salinas moran': '125605',
        'pau cubarsi paredes': '139751',
        # Major teams - verified from soccerwiki.org
        'santiago federico valverde dipetta': '81249',
        'brahim abdelkader diaz': '87941',
        'gonzalo garcia torres': '133514',
        'gabriel teodoro martinelli silva': '100768',
        'lisandro martinez': '95243',
        'jose diogo dalot teixeira': '88042',
        'manuel ugarte ribeiro': '89658',
        'matheus santos carneiro da cunha': '91556',
        'amad diallo traore': '103252',
        'nicolas gonzalez iglesias': '103484',
        'matheus luiz nunes': '102316',
        'savio moreira de oliveira': '106407',
        'robert lynch sanchez': '97528',
        'andrey nascimento dos santos': '119825',
        'pedro lomba neto': '91278',
        'joao pedro junqueira de jesus': '99631',
        'estevao willian almeida de oliveira goncalves': '128879',
        'marc guiu paz': '136703',
        'cristian gabriel romero': '86903',
        'joao maria lobo alves palhinha goncalves': '78540',
        'richarlison de andrade': '81994',
        'jonathan glao tah': '68027',
        'luis fernando diaz marulanda': '95525',
        'carlos augusto zopolato neves': '98252',
        'luis henrique tomaz de lima': '104192',
        'david neres campos': '89363',
        'daniel parejo munoz': '22857',
        'ayoze perez gutierrez': '68710',
        'nicolas pepe': '81586',
        'ederson jose dos santos lourenco da silva': '99208',
        'mile svilar': '88064',
        'bryan zaragoza martinez': '61102',
        'leonardo julian balerdi rosa': '98873',
        'emerson palmieri dos santos': '59673',
        'pedro eliezer rodriguez ledesma': '31960',
        'abner vinicius da silva santos': '100919',
        'endrick felipe moreira de sousa': '117462',
        'jose maria gimenez de vargas': '65326',
        'nahuel molina lucero': '85672',
        'julian alvarez': '99727',
        'thiago emiliano da silva': '18338',
        'mikel oyarzabal ugarte': '84791',
        'rodrigo mora de carvalho': '130093',
        'william gomes carvalho santos': '141747',
    }

    def _find_pid(player_name, team_idx=None):
        """Find pid for a player name using multiple strategies."""
        if not player_name:
            return None
        norm = _normalize(player_name)

        # 0) Manual override (highest priority)
        if norm in _PID_OVERRIDES:
            return _PID_OVERRIDES[norm]

        parts = norm.split()

        # 1) Exact match
        if norm in global_name_to_pid:
            return global_name_to_pid[norm]

        # 2) Per-team last name match (very reliable - same team + same last name)
        if team_idx is not None and team_idx in team_player_names and len(parts) >= 2:
            for tp in team_player_names[team_idx]:
                tp_parts = tp['parts']
                if len(tp_parts) >= 2 and parts[-1] == tp_parts[-1]:
                    return tp['pid']

        # 3) Last name match with disambiguation via global_last_name index
        if len(parts) >= 2 and parts[-1] in global_last_name:
            candidates = global_last_name[parts[-1]]
            if len(candidates) == 1:
                return candidates[0][0]
            # Multiple candidates - prefer same team
            if team_idx is not None:
                for pid, full_norm, td_idx in candidates:
                    if td_idx == team_idx:
                        return pid
            # Prefer matching first name initial
            for pid, full_norm, _ in candidates:
                fp = full_norm.split()
                if fp and parts[0] and fp[0][0] == parts[0][0]:
                    return pid
            return candidates[0][0]

        # 4) First name match (only if unique enough, len > 4)
        if parts and parts[0] in global_name_to_pid and len(parts[0]) > 4:
            return global_name_to_pid[parts[0]]

        # 5) Per-team scored overlap match
        if team_idx is not None and team_idx in team_player_names:
            best_match = None
            best_score = 0
            for tp in team_player_names[team_idx]:
                score = 0
                tp_parts = tp['parts']
                for pp in parts:
                    if len(pp) <= 2:
                        continue
                    for tp_p in tp_parts:
                        if pp == tp_p:
                            score += 3
                        elif pp.startswith(tp_p) or tp_p.startswith(pp):
                            score += 2
                        elif pp in tp_p or tp_p in pp:
                            score += 1
                if score > best_score:
                    best_score = score
                    best_match = tp['pid']
            if best_match and best_score >= 3:
                return best_match

        # 6) Global prefix match (fallback, limited iterations)
        count = 0
        for key, val in global_name_to_pid.items():
            if len(norm) > 5 and len(key) > 5:
                if key.startswith(norm[:8]) or norm.startswith(key[:8]):
                    return val
            count += 1
            if count > 300:
                break
        return None

    added = 0
    skipped = 0
    photo_found = 0

    for p in players_json:
        team_idx = p.get('team_index')
        if team_idx is None or team_idx not in team_idx_to_id:
            skipped += 1
            continue

        team_id = team_idx_to_id[team_idx]
        name = ext(p.get('\u0627\u0644\u0625\u0633\u0645 \u0627\u0644\u0643\u0627\u0645\u0644:')) or ext(p.get('\u0627\u0633\u0645 \u0642\u0645\u064a\u0635:'))
        if not name:
            skipped += 1
            continue

        position = ext(p.get('player_position'))
        shirt_number = extnum(p.get('\u0631\u0642\u0645 \u0627\u0644\u062a\u0634\u0643\u064a\u0644\u0629:'))
        nationality = ext(p.get('\u0627\u0644\u0623\u0645\u0629:'))
        height = extnum(p.get('\u0627\u0644\u0637\u0648\u0644(\u0633\u0645):'))
        weight = extnum(p.get('\u0627\u0644\u0648\u0632\u0646 (\u0643\u063a\u0645):'))
        rating = extnum(p.get('\u062a\u0642\u064a\u064a\u0645:'))
        preferred_foot = ext(p.get('\u0627\u0644\u0642\u062f\u0645 \u0627\u0644\u0645\u0641\u0636\u0644:'))

        # Parse age and birthdate from "العمر:" field (e.g. "37 (Mar 17, 1988)")
        age = None
        birthdate = None
        age_raw = ext(p.get('\u0627\u0644\u0639\u0645\u0631:'))
        if age_raw:
            age_match = re.match(r'(\d+)', age_raw)
            if age_match:
                age = int(age_match.group(1))
            bd_match = re.search(r'\(([^)]+)\)', age_raw)
            if bd_match:
                try:
                    from datetime import datetime
                    birthdate = datetime.strptime(bd_match.group(1).strip(), '%b %d, %Y').date()
                except (ValueError, TypeError):
                    try:
                        birthdate = datetime.strptime(bd_match.group(1).strip(), '%Y-%m-%d').date()
                    except (ValueError, TypeError):
                        pass

        # Photo URL: resolve pid from name matching, then build CDN URL
        photo_url = None
        pid = _find_pid(name, team_idx=team_idx)
        if pid:
            photo_url = f'https://cdn.soccerwiki.org/images/player/{pid}.png'
            photo_found += 1
        else:
            img = p.get('image', '')
            if img and 'spacer.gif' not in img:
                photo_url = img

        player_id = str(uuid.uuid4())

        db.add(Player(
            id=player_id,
            name=name,
            position=position or '\u063a\u064a\u0631 \u0645\u062d\u062f\u062f',
            shirt_number=shirt_number,
            nationality=nationality,
            birthdate=birthdate,
            age=age,
            height_cm=height,
            weight_kg=weight,
            photo_url=photo_url,
            market_value=float(rating) if rating else None,
            preferred_foot=preferred_foot,
            team_id=team_id,
        ))
        added += 1

        if added % 500 == 0:
            db.commit()
            logger.info(f"  Progress: {added} added, {skipped} skipped, {photo_found} with photos...")

    db.commit()
    logger.info(f"  Imported {added} players ({skipped} skipped, {photo_found} with CDN photos)")


def _verify(db):
    logger.info("Verification:")
    total_leagues = db.query(League).count()
    total_teams = db.query(Team).count()
    total_players = db.query(Player).count()
    total_coaches = db.query(Coach).count()
    total_stadiums = db.query(Stadium).count()
    players_with_photo = db.query(Player).filter(Player.photo_url.like('http%')).count()
    teams_with_logo = db.query(Team).filter(Team.logo_url.like('http%')).count()

    logger.info(f"  Leagues:   {total_leagues}")
    logger.info(f"  Teams:     {total_teams} ({teams_with_logo} with logos)")
    logger.info(f"  Players:   {total_players} ({players_with_photo} with photos)")
    logger.info(f"  Coaches:   {total_coaches}")
    logger.info(f"  Stadiums:  {total_stadiums}")

    # Show sample teams
    sample_teams = db.query(Team).limit(5).all()
    for t in sample_teams:
        cnt = db.query(Player).filter(Player.team_id == t.id).count()
        logger.info(f"    [{t.id}] {t.name}: {cnt} players, logo={t.logo_url is not None}")


if __name__ == '__main__':
    seed_v2()
