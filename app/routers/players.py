from fastapi import APIRouter, Depends, HTTPException

from sqlalchemy.orm import Session



from ..database import get_db

from ..models import Player, Team, Transfer

from ..schemas import PlayerSchema, PlayerDetailSchema, TransferSchema

# player_photos is kept for backward compat but photos/ratings are now in DB



router = APIRouter(prefix="/players", tags=["Players"])





@router.get("/", response_model=list[PlayerSchema])

def get_players(

    search: str | None = None,

    limit: int = 50,

    offset: int = 0,

    db: Session = Depends(get_db)

):

    query = db.query(Player, Team).outerjoin(Team, Player.team_id == Team.id)

    if search:

        query = query.filter(Player.name.icontains(search))

    

    results = query.order_by(Player.market_value.desc()).limit(limit).offset(offset).all()

    

    formatted_players = []

    for player, team in results:

        p_dict = {

            "id": player.id,

            "name": player.name,

            "position": player.position,

            "shirt_number": player.shirt_number,

            "nationality": player.nationality,

            "birthdate": player.birthdate,

            "height_cm": player.height_cm,

            "weight_kg": player.weight_kg,

            "photo_url": player.photo_url or '',

            "market_value": player.market_value,

            "rating": player.market_value or 0.0,

            "team_id": player.team_id,

            "team_name": team.name if team else None,

            "team_logo": team.logo_url if team else None,

        }

        formatted_players.append(p_dict)

        

    return formatted_players





@router.get("/{player_id}", response_model=PlayerDetailSchema)

def get_player(player_id: str, db: Session = Depends(get_db)):

    player = db.query(Player).filter(Player.id == player_id).first()

    if not player:

        raise HTTPException(status_code=404, detail="Player not found")



    # Get team info

    team_name = None

    team_logo = None

    if player.team_id:

        team = db.query(Team).filter(Team.id == player.team_id).first()

        if team:

            team_name = team.name

            team_logo = team.logo_url



    # Get transfers

    transfers_db = db.query(Transfer).filter(

        Transfer.player_id == player_id

    ).order_by(Transfer.transfer_date.desc()).all()



    transfers = []

    for t in transfers_db:

        from_team = db.query(Team).filter(Team.id == t.from_team_id).first() if t.from_team_id else None

        to_team = db.query(Team).filter(Team.id == t.to_team_id).first() if t.to_team_id else None

        transfers.append(TransferSchema(

            id=t.id,

            player_id=t.player_id,

            from_team_id=t.from_team_id,

            to_team_id=t.to_team_id,

            from_team_name=from_team.name if from_team else None,

            from_team_logo=from_team.logo_url if from_team else None,

            to_team_name=to_team.name if to_team else None,

            to_team_logo=to_team.logo_url if to_team else None,

            fee_amount=t.fee_amount,

            fee_currency=t.fee_currency,

            transfer_type=t.transfer_type.value if t.transfer_type else None,

            transfer_date=t.transfer_date,

        ))



    # Generate skills from rating + position

    skills = _generate_skills(player.market_value or 70, player.position or "")



    return PlayerDetailSchema(

        id=player.id,

        name=player.name,

        position=player.position,

        shirt_number=player.shirt_number,

        nationality=player.nationality,

        birthdate=player.birthdate,

        height_cm=player.height_cm,

        weight_kg=player.weight_kg,

        photo_url=player.photo_url or '',

        market_value=player.market_value,

        rating=player.market_value or 0.0,

        team_id=player.team_id,

        team_name=team_name,

        team_logo=team_logo,

        transfers=transfers,

        skills=skills,

        career_history=player.career_history,

    )





def _generate_skills(rating: float, position: str) -> dict:

    """Generate FIFA-style skill attributes from overall rating and position."""

    import hashlib

    r = max(40, min(99, int(rating)))



    # Use position hash for consistent slight variation per player

    h = int(hashlib.md5(position.encode()).hexdigest()[:8], 16) % 10



    # Position-based multipliers: [pace, shooting, passing, dribbling, defense, physical]

    pos_lower = position.strip()

    if pos_lower in ("حارس المرمى", "حم"):

        mults = [0.70, 0.55, 0.75, 0.65, 0.85, 0.80]

    elif pos_lower in ("سدادة", "دافير لعب الكرة", "عموما المدافع"):

        mults = [0.80, 0.60, 0.78, 0.70, 1.00, 0.95]

    elif pos_lower == "وينج باك":

        mults = [0.95, 0.68, 0.82, 0.80, 0.88, 0.85]

    elif pos_lower in ("لاعب خط الوسط الحائز على الكرة",):

        mults = [0.82, 0.65, 0.85, 0.78, 0.92, 0.90]

    elif pos_lower in ("لاعب خط الوسط العام", "لاعب خط وسط مربع إلى مربع", "صانع اللعب"):

        mults = [0.85, 0.78, 0.92, 0.88, 0.78, 0.82]

    elif pos_lower == "صانع لعب متقدم":

        mults = [0.85, 0.82, 0.95, 0.92, 0.60, 0.72]

    elif pos_lower == "الجناح":

        mults = [0.95, 0.80, 0.85, 0.95, 0.55, 0.70]

    elif pos_lower in ("الانتهاء", "الرجل المستهدف او المقصود"):

        mults = [0.85, 1.00, 0.75, 0.82, 0.45, 0.88]

    elif pos_lower in ("عميق الكذب إلى الأمام", "جنرال إلى الأمام"):

        mults = [0.90, 0.92, 0.82, 0.90, 0.50, 0.80]

    else:

        mults = [0.85, 0.80, 0.82, 0.82, 0.75, 0.80]



    def calc(mult, idx):

        base = int(r * mult)

        variation = ((h + idx * 3) % 7) - 3  # -3 to +3

        return max(40, min(99, base + variation))



    return {

        "pace": calc(mults[0], 0),

        "shooting": calc(mults[1], 1),

        "passing": calc(mults[2], 2),

        "dribbling": calc(mults[3], 3),

        "defense": calc(mults[4], 4),

        "physical": calc(mults[5], 5),

    }



