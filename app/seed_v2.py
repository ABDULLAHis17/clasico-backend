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

        # Always try to seed news (function is idempotent)
        _seed_news(db)

        real_player_count = db.query(Player).filter(
            Player.photo_url.like('http%')
        ).count()
        real_team_count = db.query(Team).filter(
            Team.logo_url.like('http%'), ~Team.id.like('t%')
        ).count()

        if real_team_count > 50 and real_player_count > 500:
            logger.info("Real data already seeded, skipping full import.")
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
        # Re-run news after leagues are imported so league_id FK matches
        _seed_news(db)
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

    # Manual PID → photo URL overrides for specific players
    PLAYER_PHOTO_OVERRIDES = {
        # Mohamed Salah – use clean Sofifa CDN image
        'Mohamed Salah Hamed Mahrous Ghaly': 'https://cdn.sofifa.net/players/209/331/24_120.png',
        'M.SALAH': 'https://cdn.sofifa.net/players/209/331/24_120.png',
    }

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

        # Photo URL: check manual overrides first, then resolve pid, then fall back
        photo_url = None
        shirt_name = ext(p.get('\u0627\u0633\u0645 \u0642\u0645\u064a\u0635:'))
        if name in PLAYER_PHOTO_OVERRIDES:
            photo_url = PLAYER_PHOTO_OVERRIDES[name]
            photo_found += 1
        elif shirt_name and shirt_name in PLAYER_PHOTO_OVERRIDES:
            photo_url = PLAYER_PHOTO_OVERRIDES[shirt_name]
            photo_found += 1
        else:
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


def _seed_news(db):
    """Seed football news articles if none exist."""
    from datetime import datetime
    existing = db.query(News).count()
    if existing > 0:
        logger.info(f"  News already seeded ({existing} items), skipping.")
        return

    logger.info("Seeding news articles...")

    # Fetch league IDs dynamically
    from app.models import League
    leagues = {l.name: l.id for l in db.query(League).all()}

    def get_league_id(*names):
        for n in names:
            for k, v in leagues.items():
                if n.lower() in k.lower():
                    return v
        return None

    pl_id  = get_league_id('Premier', 'England')
    laliga = get_league_id('La Liga', 'Spain', 'Primera')
    ucl    = get_league_id('Champions', 'UEFA')
    seria  = get_league_id('Serie A', 'Italy')
    bund   = get_league_id('Bundesliga', 'Germany')

    news_data = [
        {
            'id': str(uuid.uuid4()),
            'title': 'محمد صلاح يُجدد عقده مع ليفربول حتى 2027',
            'summary': 'أعلن نادي ليفربول الإنجليزي رسمياً تجديد عقد نجمه المصري محمد صلاح لمدة عامين إضافيين، ليبقى بالأنفيلد حتى عام 2027.',
            'content': 'وقّع محمد صلاح عقداً جديداً مع نادي ليفربول الإنجليزي يمتد حتى عام 2027، وذلك في صفقة تعاقدية ضخمة تُعدّ من الأغلى في تاريخ الدوري الإنجليزي الممتاز. يأتي هذا التجديد بعد مفاوضات مطوّلة استمرت عدة أشهر، وأكد المصري "الفرعون" التزامه التام بالنادي وطموحه للفوز بألقاب جديدة مع الريدز.',
            'language': 'ar',
            'source': 'Liverpool FC Official',
            'url': 'https://www.liverpoolfc.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/2/26/Mohamed_Salah_2018.jpg/440px-Mohamed_Salah_2018.jpg',
            'published_at': datetime(2025, 5, 15, 10, 0),
            'league_id': pl_id,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'ريال مدريد يُتوّج بلقب دوري أبطال أوروبا للمرة الـ15',
            'summary': 'حقق ريال مدريد إنجازاً تاريخياً بفوزه بلقب دوري أبطال أوروبا للمرة الخامسة عشرة في تاريخه، بعد انتصار مثير على بايرن ميونيخ.',
            'content': 'توّج ريال مدريد الإسباني بلقب دوري أبطال أوروبا للموسم الحالي، ليضيف رقماً قياسياً جديداً إلى سجله التاريخي الحافل. جاء الفوز في نهائي مشوّق أمام بايرن ميونيخ الألماني، حيث أبدع فينيسيوس جونيور وكيليان مبابي في الهجوم، فيما صدّ تيبو كورتوا كرات خطيرة لإنقاذ الفوز.',
            'language': 'ar',
            'source': 'UEFA Champions League',
            'url': 'https://www.uefa.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/en/5/56/Real_Madrid_CF.svg',
            'published_at': datetime(2025, 5, 31, 22, 0),
            'league_id': ucl,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'مبابي يسجل هاتريك في أول مواجهة بالكلاسيكو',
            'summary': 'سجّل النجم الفرنسي كيليان مبابي ثلاثة أهداف في أولى مواجهاته بالكلاسيكو، ليقود ريال مدريد لفوز مثير على برشلونة.',
            'content': 'كتب كيليان مبابي تاريخاً جديداً بتسجيله هاتريكاً في أولى مشاركاته في كلاسيكو الأرض، إذ قاد ريال مدريد لانتصار كبير على برشلونة بثلاثة أهداف مقابل هدف. أبدى الفرنسي أداءً استثنائياً بسرعته الخارقة وإنهائه الحاد، ليُبرهن أنه خليفة كريستيانو رونالدو في قلوب الجماهير البيضاء.',
            'language': 'ar',
            'source': 'Marca',
            'url': 'https://www.marca.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/en/4/47/FC_Barcelona_%28crest%29.svg',
            'published_at': datetime(2025, 4, 26, 20, 0),
            'league_id': laliga,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'مانشستر سيتي يوقع مع نجم إنتر ميلان في صفقة الصيف',
            'summary': 'نجح مانشستر سيتي في التعاقد مع النجم الدولي من إنتر ميلان في صفقة انتقال حرة خلال سوق الصيف.',
            'content': 'أعلن نادي مانشستر سيتي الإنجليزي عن إتمام صفقة انتقال لاعب إنتر ميلان البارز، ليكون الإضافة الكبيرة لتعزيز الفريق في موسم جديد. جاءت الصفقة بعد مفاوضات طويلة وتنافس من كبار الأندية الأوروبية، وقال المدرب بيب غوارديولا إن الصفقة ستعزز خيارات الفريق على أعلى مستوى.',
            'language': 'ar',
            'source': 'Manchester City FC',
            'url': 'https://www.mancity.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/en/e/eb/Manchester_City_FC_badge.svg',
            'published_at': datetime(2025, 6, 10, 14, 0),
            'league_id': pl_id,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'ليفربول يُسقط مانشستر يونايتد في ديربي الأحلام',
            'summary': 'حقق ليفربول انتصاراً مدوياً على منافسه التاريخي مانشستر يونايتد في مواجهة رائعة بالأنفيلد.',
            'content': 'أقام الأنفيلد احتفالاً كبيراً بعد فوز ليفربول الكبير على مانشستر يونايتد في لقاء كلاسيكو الدوري الإنجليزي الممتاز. برز محمد صلاح وداروين نونييز في الهجوم، فيما تألق ألسون بيكر في المرمى لإحكام قفل الشباك أمام الشياطين الحمر.',
            'language': 'ar',
            'source': 'Premier League',
            'url': 'https://www.premierleague.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/en/0/0c/Liverpool_FC.svg',
            'published_at': datetime(2025, 3, 5, 17, 30),
            'league_id': pl_id,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'برشلونة يُعلن عن توقيع عقد المدرب الجديد لموسم 2025-26',
            'summary': 'أعلن نادي برشلونة عن تعيين مدرب جديد لتولي دفة القيادة بدءاً من الموسم المقبل خلفاً للمدرب الحالي.',
            'content': 'كشف نادي برشلونة عن هوية المدرب الجديد الذي سيقود الفريق في مغامرة موسم 2025-2026، وذلك في مؤتمر صحفي حضره رئيس النادي جوان لابورتا. تعاقد النادي مع المدرب وفق خطة تطويرية شاملة تهدف إلى استعادة المجد في أوروبا.',
            'language': 'ar',
            'source': 'FC Barcelona',
            'url': 'https://www.fcbarcelona.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/en/4/47/FC_Barcelona_%28crest%29.svg',
            'published_at': datetime(2025, 5, 20, 12, 0),
            'league_id': laliga,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'بايرن ميونيخ يُتوج بلقب البوندسليغا للموسم الثاني عشر توالياً',
            'summary': 'واصل بايرن ميونيخ هيمنته على الدوري الألماني بتتويجه بلقب البوندسليغا مجدداً، محققاً رقماً قياسياً عالمياً.',
            'content': 'أكمل بايرن ميونيخ مسيرة مثيرة في البوندسليغا بفوزه باللقب للعام الثاني عشر على التوالي، وهو رقم يصعب تكراره في تاريخ كرة القدم العالمية. قاد المدرب فانسان كومباني الفريق في موسم متميز ظهرت فيه مواهب شابة إلى جانب نجوم الفريق المعتادين.',
            'language': 'ar',
            'source': 'Bundesliga Official',
            'url': 'https://www.bundesliga.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/FC_Bayern_M%C3%BCnchen_logo_%282017%29.svg/440px-FC_Bayern_M%C3%BCnchen_logo_%282017%29.svg.png',
            'published_at': datetime(2025, 4, 12, 18, 0),
            'league_id': bund,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'يامال يُبهر العالم بأداء أسطوري في دوري أبطال أوروبا',
            'summary': 'أذهل النجم الإسباني الشاب لامين يامال العالم بأداء فردي خارق في المراحل الإقصائية من دوري أبطال أوروبا.',
            'content': 'استمر لامين يامال في رسم مساره الاستثنائي في عالم كرة القدم، بعد تقديم عرض مذهل في دوري أبطال أوروبا. رسم الشاب الإسباني ذو السبعة عشر عاماً مستقبلاً باهراً بأسلوبه اللماح وإبداعه التكتيكي، مثيراً إعجاب خبراء الكرة في أوروبا وخارجها.',
            'language': 'ar',
            'source': 'UEFA',
            'url': 'https://www.uefa.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/en/4/47/FC_Barcelona_%28crest%29.svg',
            'published_at': datetime(2025, 4, 8, 21, 0),
            'league_id': ucl,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'أرسنال يقتنص صدارة الدوري الإنجليزي بعد فوز صعب',
            'summary': 'تمكن أرسنال من اقتناص صدارة الدوري الإنجليزي الممتاز بعد فوز مثير على فريق قوي في الجولة ما قبل الأخيرة.',
            'content': 'خطا أرسنال خطوة كبيرة نحو لقب الدوري الإنجليزي الممتاز بعد فوزه الصعب في مباراة خرجت بعدة تقلبات درامية. قاد بوكايو ساكا وليئاندرو تروساردي الهجوم بأداء متميز، فيما صمد الدفاع أمام هجمات المنافس في الدقائق الأخيرة.',
            'language': 'ar',
            'source': 'Arsenal FC',
            'url': 'https://www.arsenal.com',
            'image_url': 'https://upload.wikimedia.org/wikipedia/en/5/53/Arsenal_FC.svg',
            'published_at': datetime(2025, 5, 4, 16, 0),
            'league_id': pl_id,
        },
        {
            'id': str(uuid.uuid4()),
            'title': 'يوفنتوس يُعلن عودة اللاعب الإيطالي تشيزاري بيسيريف',
            'summary': 'أعلن نادي يوفنتوس الإيطالي عن إتمام صفقة عودة أحد أبرز نجومه السابقين في خطوة مفاجئة لجماهير السيدة العجوز.',
            'content': 'فاجأ نادي يوفنتوس الجماهير الإيطالية والأوروبية بإعلانه عن إتمام صفقة انتقال مدوية، في محاولة جادة منه للعودة لمنافسة الأندية الكبرى في دوري أبطال أوروبا. تأتي هذه الصفقة ضمن مشروع إعادة البناء الذي يتبناه النادي التوريني.',
            'language': 'ar',
            'source': 'Serie A',
            'url': 'https://www.legaseriea.it',
            'image_url': 'https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Juventus_FC_2017_icon_%28black%29.svg/440px-Juventus_FC_2017_icon_%28black%29.svg.png',
            'published_at': datetime(2025, 6, 2, 11, 0),
            'league_id': seria,
        },
    ]

    count = 0
    for item in news_data:
        news = News(
            id=item['id'],
            title=item['title'],
            summary=item['summary'],
            content=item['content'],
            language=item['language'],
            source=item['source'],
            url=item['url'],
            image_url=item['image_url'],
            published_at=item['published_at'],
            league_id=item.get('league_id'),
            team_id=None,
            player_id=None,
        )
        db.add(news)
        count += 1

    db.commit()
    logger.info(f"  Seeded {count} news articles.")


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
