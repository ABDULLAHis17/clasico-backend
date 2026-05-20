from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session
import json

from ..database import get_db
from ..models import Team, League
from ..schemas import TeamSchema, TeamDetailSchema

router = APIRouter(prefix="/teams", tags=["Teams"])


@router.get("/")
def get_teams(
    search: str | None = None,
    team_type: str | None = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    query = db.query(Team, League).outerjoin(League, Team.league_id == League.id)
    if search:
        query = query.filter(Team.name.icontains(search))
    if team_type:
        query = query.filter(Team.type == team_type)

    results = query.order_by(Team.name).limit(limit).offset(offset).all()

    return [
        {
            "id": t.id,
            "name": t.name,
            "short_name": t.short_name,
            "logo_url": t.logo_url,
            "country": t.country,
            "founded_year": t.founded_year,
            "league_id": t.league_id,
            "stadium_id": t.stadium_id,
            "type": t.type.name if t.type else None,
            "league_name": l.name if l else None,
            "league_logo": l.logo_url if l else None,
        }
        for t, l in results
    ]


from ..models import Team, Player, Stadium, League, Coach

# Maps full JSON team names → actual DB abbreviated names
_NAME_OVERRIDES = {
    "internazionale": "I Milan", "inter milan": "I Milan",
    "juventus": "J Torino", "as roma": "Roma", "ss lazio": "Lazio", "ssc napoli": "Napoli",
    "acf fiorentina": "Fiorentina", "atalanta bc": "Atalanta", "bologna fc": "Bologna",
    "chelsea": "Chlsea", "aston villa": "Aston V", "afc bournemouth": "Bournemouth",
    "rb leipzig": "Leipzig",
    "cr flamengo": "Flamengo", "vissel kobe": "V Kobe", "club brugge kv": "C Bruges",
    "cercle brugge": "Bruges", "royal antwerp": "Antwerp", "santos laguna": "Santos",
    "kyoto sanga": "Kyoto", "sanfrecce hiroshima": "S Hiroshima",
    "club america": "CA Xochimilco", "club leon": "C. Leon", "club puebla": "Puebla", "club tijuana": "Tijuana",
    "athletic club": "A Bilbao", "deportivo alaves": "Alaves", "deportivo riestra": "Riestra", "deportivo toluca": "Toluca",
    "brighton & hove albion": "Brighton", "brighton and hove albion": "Brighton",
    "borussia monchengladbach": "Mgladbach",
    "wolverhampton wanderers": "Wolverhampton", "nottingham forest": "Nottingham F",
    "queens park rangers": "QPR", "crystal palace": "C Palace", "west bromwich albion": "W Bromwich",
    "stade brestois 29": "Brest", "stade rennais": "Rennes", "lille osc": "Lille", "angers sco": "Angers",
    "ogc nice": "Nice", "rc lens": "Lens", "rc strasbourg alsace": "Strasbourg", "le havre ac": "Le Havre",
    "olympique marseille": "Marseille", "olympique lyonnais": "Lyon",
    "ol. marseille": "Marseille", "ol. lyonnais": "Lyon",
    "sl benfica": "B Lisbon", "sporting cp": "S Lisbon", "sc braga": "Braga",
    "botafogo fr": "Botafogo", "cruzeiro ec": "Cruzeiro", "ec bahia": "B Salvador", "ec vitoria": "V Salvador",
    "chapecoense af": "Chapeco", "rb bragantino": "Braganca Paulista", "mirassol fc": "Mirassol",
    "sc internacional": "I Porto Alegre",
    "boca juniors": "Boca", "racing club": "I Avellaneda", "newells old boys": "N Rosario",
    "newell's old boys": "N Rosario",
    "rosario central": "Rosario C",
    "estudiantes de la plata": "E La Plata", "argentinos juniors": "La Paternal",
    "central cordoba sde": "Santiago del Estero", "gimnasia la plata": "G La Plata",
    "independiente rivadavia": "Rivadavia", "barracas central": "Barracas C",
    "velez sarsfield": "VS Liniers",
    "tigres uanl": "Tigres UANL", "unam pumas": "P Mexico City", "pumas unam": "P Mexico City",
    "fc juarez": "Juarez", "mazatlan fc": "Mazatlan",
    "ajax": "A Amsterdam", "feyenoord": "F Rotterdam", "psv": "P Eindhoven",
    "az alkmaar": "AZ Alkmaar", "fc twente": "T Enschede", "fc utrecht": "Utrecht",
    "sc heerenveen": "Heerenveen", "heracles almelo": "H Almelo", "nec nijmegen": "NEC",
    "fc groningen": "Groningen", "pec zwolle": "Zwolle", "fc volendam": "Volendam",
    "sparta rotterdam": "S Rotterdam", "nac breda": "Breda", "go ahead eagles": "G Deventer",
    "fortuna sittard": "F Sittard", "sbv excelsior": "T Velsen", "telstar": "Telstar", "dender eh": "Dender",
    "kvc westerlo": "Westerlo", "kv mechelen": "Mechelen", "kaa gent": "Gent", "krc genk": "Genk",
    "rsc anderlecht": "Anderlecht", "standard liege": "S Liege", "sporting charleroi": "Charleroi",
    "union saint-gilloise": "Union SG", "sint-truidense vv": "Sint-Truiden", "raal la louviere": "La Louviere",
    "zulte waregem": "Z Waregem",
    "sporting kansas city": "Sporting KC", "los angeles galaxy": "Los Angeles G",
    "los angeles fc": "Los Angeles", "new england revolution": "N England",
    "inter miami cf": "Miami", "new york rb": "New York R", "new york city fc": "New York",
    "cf montreal": "Montreal", "d.c. united": "Washington D.C.",
    "galatasaray sk": "G Istanbul", "fenerbahce sk": "Fenerbahce", "besiktas jk": "Besiktas",
    "trabzonspor": "Trabzon", "istanbul basaksehir": "Basaksehir",
    "alanyaspor": "Alanya", "antalyaspor": "Antalya", "konyaspor": "Konya",
    "kayserispor": "Kayseri", "kasimpasa sk": "Kasimpasa", "gaziantep fk": "Gaziantep",
    "fatih karagumruk": "Karagumruk", "goztepe sk": "Guzelyali", "caykur rizespor": "Rize",
    "genclerbirligi": "Genclerbirligi", "gençlerbirliği": "Genclerbirligi",
    "al hilal sfc": "Al Hilal", "al nassr fc": "Al Nassr", "al ittihad club": "Al Ittihad",
    "al ahli sfc": "Jeddah", "al shabab fc": "Al Shabab", "al riyadh sc": "Al Riyadh",
    "al ettifaq": "Al Ettifaq", "al fateh sc": "Al Fateh", "al fayha fc": "Al Fayha",
    "al hazem sc": "Al Hazem", "al khaleej fc": "Al Khaleej", "al kholood club": "Al Kholood",
    "al okhdood club": "Al Okhdood", "al qadsiah fc": "Al Qadsiah", "damac fc": "Damac",
    "al najma sc": "Al Najma", "neom sc": "Neom",
    "kashima antlers": "Kashima", "urawa red diamonds": "UR Saitama", "yokohama f. marinos": "Yokohama M",
    "kawasaki frontale": "Kawasaki", "nagoya grampus": "Nagoya", "gamba osaka": "G Osaka",
    "cerezo osaka": "C Osaka", "fc tokyo": "F Tokyo",
    "kashiwa reysol": "Kashiwa", "avispa fukuoka": "A Fukuoka", "shimizu s-pulse": "S Shizuoka",
    "jef united chiba": "JEF United", "v-varen nagasaki": "V-Varen", "fagiano okayama": "Fagiano",
    "machida zelvia": "Machida", "mito hollyhock": "Mito",
    "bayer leverkusen": "Leverkusen", "eintracht frankfurt": "E. Frankfurt",
    "fc augsburg": "Augsburg", "fc st. pauli": "St. Pauli", "vfb stuttgart": "Stuttgart",
    "vfl wolfsburg": "Wolfsburg", "werder bremen": "Bremen", "tsg 1899 hoffenheim": "Sinsheim",
    "sc freiburg": "Freiburg", "hamburger sv": "Hamburg", "1. fc heidenheim 1846": "Heidenheim",
    "1. fc koln": "Cologne", "1. fc köln": "Cologne", "1. fc union berlin": "U Berlin", "1. fsv mainz 05": "Mainz",
    "como 1907": "Como", "genoa cfc": "Genoa", "hellas verona": "Verona",
    "parma calcio 1913": "Parma", "us cremonese": "Cremonese",
    "us lecce": "Lecce", "us sassuolo": "Sassuolo", "pisa sc": "Pisa",
    "rcd mallorca": "Mallorca",
    "real betis": "Betis", "real oviedo": "Oviedo", "real sociedad": "R Sociedad",
    "getafe cf": "Getafe", "levante ud": "Levante",
    "elche cf": "Elche", "girona fc": "Girona", "sevilla fc": "Sevilla",
    "villarreal cf": "Villarreal",
    "clube do remo": "Remo", "coritiba": "A Curitiba",
    "athletico paranaense": "A Curitiba", "atletico mineiro": "Minas Gerais",
    "atletico tucuman": "A Tucuman", "atletico san luis": "San Luis Potosi",
    "ca talleres": "T Cordoba", "ca huracan": "Huracan", "ca aldosivi": "Aldosivi",
    "ca platense": "Platense", "ca sarmiento": "Sarmiento", "ca tigre": "Tigre",
    "ca union": "C Union", "ca osasuna": "O Pamplona",
    "estudiantes de rio cuarto": "E Rio Cuarto", "gimnasia de mendoza": "Gimnasia M",
    "independiente": "I Avellaneda", "san lorenzo": "San Lorenzo", "river plate": "RP Nunez",
    "cruz azul": "Cruz Azul", "necaxa": "N Aguascalientes", "atlas": "Atlas", "queretaro fc": "Queretaro",
    "defensa y justicia": "Defensa y Justicia",
    "fc lorient": "Lorient", "fc metz": "Metz", "fc nantes": "Nantes", "fc porto": "Porto",
    "toulouse fc": "Toulouse", "aj auxerre": "Auxerre",
    "cd nacional": "N Funchal", "cd santa clara": "Ponta Delgada", "cd tondela": "Tondela",
    "casa pia ac": "Casa Pia", "estrela da amadora": "Estrela", "gd estoril praia": "Estoril",
    "fc arouca": "Arouca", "fc famalicao": "Familicao", "fc alverca": "Alverca",
    "gil vicente fc": "Barcelos", "moreirense fc": "Moreira de Conegos", "vitoria guimaraes sc": "Vitoria SC",
    "avs futebol sad": "AVS",
    "santos fc": "Santos", "palmeiras": "Palmeiras", "corinthians": "A Curitiba",
    "fluminense": "Fluminense", "gremio": "Gremio", "grêmio": "Gremio", "vasco da gama": "Vasco",
    "sao paulo fc": "Sao Paulo",
    "birmingham city": "Birmingham", "blackburn rovers": "Blackburn",
    "bristol city": "Bristol C", "coventry city": "Coventry", "derby county": "Derby",
    "hull city": "Hull", "ipswich town": "Ipswich", "leeds united": "Leeds",
    "leicester city": "Leicester", "norwich city": "Norwich", "oxford united": "Oxford",
    "preston north end": "Preston", "sheffield wednesday": "Sheffield W",
    "stoke city": "Stoke", "swansea city": "Swansea", "charlton athletic": "Charlton",
    "san diego fc": "San Diego", "st. louis city sc": "St Louis",
    "seattle sounders": "Seattle", "portland timbers": "Portland",
    "minnesota united": "Minnesota", "philadelphia union": "Philadelphia",
    "charlotte fc": "Charlotte", "orlando city sc": "Orlando", "nashville sc": "Nashville",
    "columbus crew": "Columbus", "fc cincinnati": "Cincinnati", "chicago fire": "Chicago",
    "fc dallas": "Dallas", "houston dynamo": "Houston", "colorado rapids": "Colorado",
    "real salt lake": "Salt Lake", "san jose earthquakes": "San Jose", "austin fc": "Austin",
    "vancouver whitecaps": "Vancouver", "toronto fc": "Toronto", "atlanta united": "Atlanta",
}


def _abbrev_name(full: str) -> list[str]:
    """Generate possible DB abbreviations for a full team name.
    e.g. 'Manchester United' → ['Manchester U', 'M United', 'Manchester United']
         'West Ham United' → ['West Ham U', 'W Ham', 'W Ham United', 'West Ham United']
         'Real Madrid' → ['R Madrid', 'Real M']
    """
    parts = full.strip().split()
    variants = [full]
    if len(parts) >= 2:
        # First word + initial of last word: "Manchester U"
        variants.append(f"{parts[0]} {parts[-1][0]}")
        # Initial of first word + second word: "R Madrid"
        variants.append(f"{parts[0][0]} {parts[1]}")
        # For 3+ words: first two words + initial of last: "West Ham U"
        if len(parts) >= 3:
            variants.append(f"{parts[0]} {parts[1]} {parts[-1][0]}")
            # First initial + second word + last initial: "W Ham U"
            variants.append(f"{parts[0][0]} {parts[1]} {parts[-1][0]}")
            # First two words: "West Ham"
            variants.append(f"{parts[0]} {parts[1]}")
            # First initial + second word: "W Ham"
            variants.append(f"{parts[0][0]} {parts[1]}")
        # First word only for matching
        variants.append(parts[0])
    return variants

def _normalize_for_lookup(s: str) -> str:
    """Normalize accented characters for override lookup."""
    import re
    s = s.lower().strip()
    for src, dst in [('ö','o'),('ü','u'),('ä','a'),('é','e'),('è','e'),('ê','e'),('ë','e'),
                     ('á','a'),('à','a'),('â','a'),('ã','a'),('í','i'),('ì','i'),('î','i'),
                     ('ï','i'),('ó','o'),('ò','o'),('ô','o'),('õ','o'),('ú','u'),('ù','u'),
                     ('û','u'),('ć','c'),('č','c'),('ç','c'),('š','s'),('ž','z'),('đ','d'),
                     ('ñ','n'),('ń','n'),('ß','ss'),('ğ','g'),('ê','e'),('ô','o')]:
        s = s.replace(src, dst)
    s = re.sub(r'[^a-z0-9\s\'&.-]', '', s)
    s = re.sub(r'\s+', ' ', s).strip()
    return s

def _match_team_name(search: str, db: Session) -> object | None:
    """Try multiple strategies to find a team by name, handling short DB names vs full JSON names."""
    # 0) Manual override (try original and normalized)
    for key in [search.lower().strip(), _normalize_for_lookup(search)]:
        override = _NAME_OVERRIDES.get(key)
        if override:
            team = db.query(Team).filter(Team.name.ilike(override)).first()
            if team:
                return team
    # 1) Exact match
    team = db.query(Team).filter(Team.name == search).first()
    if team:
        return team
    # 2) Case-insensitive exact match
    team = db.query(Team).filter(Team.name.ilike(search)).first()
    if team:
        return team
    # 3) Try all abbreviation variants
    for variant in _abbrev_name(search):
        team = db.query(Team).filter(Team.name.ilike(variant)).first()
        if team:
            return team
    # 4) For multi-word, try matching by first word + last-word initial
    parts = search.strip().split()
    if len(parts) >= 2 and len(parts[0]) > 3:
        candidates = db.query(Team).filter(Team.name.ilike(f"{parts[0]}%")).all()
        if len(candidates) == 1:
            return candidates[0]
        if candidates:
            # Match by last word initial
            for c in candidates:
                c_parts = c.name.strip().split()
                if len(c_parts) >= 2 and c_parts[-1][0].lower() == parts[-1][0].lower():
                    return c
    # 5) Partial match — pick best scoring candidate
    all_teams = db.query(Team).all()
    best, best_score = None, 0
    search_lower = search.lower()
    for t in all_teams:
        t_lower = t.name.lower()
        score = 0
        if t_lower in search_lower or search_lower in t_lower:
            score = 10
        # Word overlap
        search_words = set(search_lower.split())
        team_words = set(t_lower.split())
        overlap = search_words & team_words
        if overlap:
            score = max(score, len(overlap) * 5)
        # Initial matching: each word in search matches initial of a word in team
        if len(overlap) == 0 and len(parts) >= 2:
            initials_match = sum(1 for w in search_words if any(tw.startswith(w[0]) for tw in team_words))
            if initials_match >= 2:
                score = max(score, initials_match * 2)
        if score > best_score:
            best, best_score = t, score
    return best


@router.get("/by-name/{name}")
def get_team_by_name(name: str, db: Session = Depends(get_db)):
    team = _match_team_name(name, db)
    if not team:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Team not found")
    players_db = db.query(Player).filter(Player.team_id == team.id).all()
    stadium = db.query(Stadium).filter(Stadium.id == team.stadium_id).first() if team.stadium_id else None
    league = db.query(League).filter(League.id == team.league_id).first() if team.league_id else None
    coach = db.query(Coach).filter(Coach.team_id == team.id).first()

    pos_priority = {
        "حارس المرمى": 1, "حم": 1, "gk": 1,
        "سدادة": 2, "دافير لعب الكرة": 2, "عموما المدافع": 2, "وينج باك": 2, "مدافع": 2, "d": 2,
        "لاعب خط الوسط الحائز على الكرة": 3, "لاعب خط الوسط العام": 3, "لاعب خط وسط مربع إلى مربع": 3,
        "صانع اللعب": 3, "صانع لعب متقدم": 3, "صانع الالعاب المتاخر": 3, "m": 3,
        "الجناح": 4, "الانتهاء": 4, "الرجل المستهدف او المقصود": 4, "عميق الكذب إلى الأمام": 4,
        "جنرال إلى الأمام": 4, "إلى الأمام واسعة": 4, "صل": 4, "f": 4
    }

    def get_pos_rank(pos):
        if not pos: return 99
        pos = pos.lower()
        if pos in pos_priority: return pos_priority[pos]
        if "حارس" in pos: return 1
        if "مدافع" in pos or "سدادة" in pos: return 2
        if "وسط" in pos or "صانع" in pos: return 3
        if "هجوم" in pos or "جناح" in pos or "مهاجم" in pos: return 4
        return 99

    players = sorted(players_db, key=lambda p: (get_pos_rank(p.position), -(p.market_value or 0)))
    ratings = [p.market_value for p in players_db if p.market_value]
    avg_rating = sum(ratings) / len(ratings) if ratings else 0.0
    top_rating = max(ratings) if ratings else 0.0

    cups_data = None
    cups_date_data = None
    total_trophies = 0
    if team.cups:
        try:
            cups_data = json.loads(team.cups)
            for cup_name, cup_val in cups_data.items():
                if isinstance(cup_val, dict):
                    total_trophies += int(cup_val.get('text', '0') or '0')
        except: pass
    if team.cups_date:
        try:
            cups_date_data = json.loads(team.cups_date)
            cups_keys = set(cups_data.keys()) if cups_data else set()
            counted_labels = set()
            for cd in cups_date_data:
                if isinstance(cd, dict):
                    label = cd.get('label', '')
                    text_val = cd.get('text', '')
                    if label and label not in cups_keys:
                        try:
                            num_val = int(text_val)
                            is_year = 1800 <= num_val <= 2099
                            if is_year:
                                total_trophies += 1
                            elif label not in counted_labels:
                                counted_labels.add(label)
                                total_trophies += num_val
                        except (ValueError, TypeError):
                            total_trophies += 1
        except: pass

    return {
        "id": team.id,
        "name": team.name,
        "short_name": team.short_name,
        "logo_url": team.logo_url,
        "country": team.country,
        "founded_year": team.founded_year,
        "league_id": team.league_id,
        "stadium_id": team.stadium_id,
        "type": team.type.name if team.type else None,
        "league_name": league.name if league else None,
        "league_logo": league.logo_url if league else None,
        "stadium_name": stadium.name if stadium else None,
        "stadium_city": stadium.city if stadium else None,
        "stadium_capacity": stadium.capacity if stadium else None,
        "stadium_image": stadium.image_url if stadium else None,
        "squad_size": len(players_db),
        "avg_rating": round(avg_rating, 1),
        "top_rating": top_rating,
        "total_trophies": total_trophies,
        "cups": cups_data,
        "cups_date": cups_date_data,
        "coach": {
            "id": coach.id,
            "name": coach.name,
            "photo_url": coach.photo_url,
        } if coach else None,
        "players": [
            {
                "id": p.id,
                "name": p.name,
                "position": p.position,
                "shirt_number": p.shirt_number,
                "nationality": p.nationality,
                "birthdate": p.birthdate,
                "age": p.age,
                "height_cm": p.height_cm,
                "weight_kg": p.weight_kg,
                "photo_url": p.photo_url,
                "market_value": p.market_value,
                "preferred_foot": p.preferred_foot,
            }
            for p in players
        ]
    }


@router.get("/{team_id}")
def get_team(team_id: str, db: Session = Depends(get_db)):
    team = db.query(Team).filter(Team.id == team_id).first()
    if not team:
        from fastapi import HTTPException
        raise HTTPException(status_code=404, detail="Team not found")
    players_db = db.query(Player).filter(Player.team_id == team_id).all()
    stadium = db.query(Stadium).filter(Stadium.id == team.stadium_id).first() if team.stadium_id else None
    league = db.query(League).filter(League.id == team.league_id).first() if team.league_id else None

    squad_size = len(players_db)
    ratings = [p.market_value for p in players_db if p.market_value]
    avg_rating = sum(ratings) / len(ratings) if ratings else 0.0
    top_rating = max(ratings) if ratings else 0.0

    # Define position priority map
    pos_priority = {
        # GK
        "حارس المرمى": 1, "حم": 1, "gk": 1,
        # DF
        "سدادة": 2, "دافير لعب الكرة": 2, "عموما المدافع": 2, "وينج باك": 2, "مدافع": 2, "d": 2,
        # MF
        "لاعب خط الوسط الحائز على الكرة": 3, "لاعب خط الوسط العام": 3, "لاعب خط وسط مربع إلى مربع": 3,
        "صانع اللعب": 3, "صانع لعب متقدم": 3, "صانع الالعاب المتاخر": 3, "m": 3, "וד": 3,
        # FW
        "الجناح": 4, "الانتهاء": 4, "الرجل المستهدف او المقصود": 4, "عميق الكذب إلى الأمام": 4,
        "جنرال إلى الأمام": 4, "إلى الأمام واسعة": 4, "صل": 4, "f": 4
    }

    def get_pos_rank(pos):
        if not pos: return 99
        pos = pos.lower()
        # Direct match
        if pos in pos_priority: return pos_priority[pos]
        # Partial match
        if "حارس" in pos: return 1
        if "مدافع" in pos or "سدادة" in pos: return 2
        if "وسط" in pos or "صانع" in pos: return 3
        if "هجوم" in pos or "جناح" in pos or "مهاجم" in pos: return 4
        return 99

    # Sort players by rank, then by market value (rating)
    players = sorted(players_db, key=lambda p: (get_pos_rank(p.position), -(p.market_value or 0)))

    # Parse trophy data
    cups_data = None
    cups_date_data = None
    total_trophies = 0
    if team.cups:
        try:
            cups_data = json.loads(team.cups)
            for cup_name, cup_val in cups_data.items():
                if isinstance(cup_val, dict):
                    total_trophies += int(cup_val.get('text', '0') or '0')
        except: pass
    if team.cups_date:
        try:
            cups_date_data = json.loads(team.cups_date)
            cups_keys = set(cups_data.keys()) if cups_data else set()
            counted_labels = set()
            for cd in cups_date_data:
                if isinstance(cd, dict):
                    label = cd.get('label', '')
                    text_val = cd.get('text', '')
                    if label and label not in cups_keys:
                        try:
                            num_val = int(text_val)
                            is_year = 1800 <= num_val <= 2099
                            if is_year:
                                total_trophies += 1
                            elif label not in counted_labels:
                                counted_labels.add(label)
                                total_trophies += num_val
                        except (ValueError, TypeError):
                            total_trophies += 1
        except: pass

    return {
        "id": team.id,
        "name": team.name,
        "short_name": team.short_name,
        "logo_url": team.logo_url,
        "country": team.country,
        "founded_year": team.founded_year,
        "league_id": team.league_id,
        "stadium_id": team.stadium_id,
        "type": team.type.name if team.type else None,
        "league_name": league.name if league else None,
        "league_logo": league.logo_url if league else None,
        "stadium_name": stadium.name if stadium else None,
        "stadium_city": stadium.city if stadium else None,
        "stadium_capacity": stadium.capacity if stadium else None,
        "stadium_image": stadium.image_url if stadium else None,
        "squad_size": squad_size,
        "avg_rating": round(avg_rating, 1),
        "top_rating": top_rating,
        "total_trophies": total_trophies,
        "cups": cups_data,
        "cups_date": cups_date_data,
        "players": [
            {
                "id": p.id,
                "name": p.name,
                "position": p.position,
                "shirt_number": p.shirt_number,
                "nationality": p.nationality,
                "birthdate": p.birthdate,
                "age": p.age,
                "height_cm": p.height_cm,
                "weight_kg": p.weight_kg,
                "photo_url": p.photo_url,
                "market_value": p.market_value,
                "preferred_foot": p.preferred_foot,
            }
            for p in players
        ]
    }
