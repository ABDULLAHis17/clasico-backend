from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Stadium
from ..schemas import StadiumSchema

router = APIRouter(prefix="/stadiums", tags=["Stadiums"])

@router.get("/", response_model=list[StadiumSchema])
def get_stadiums(
    search: str | None = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    query = db.query(Stadium)
    if search:
        query = query.filter(Stadium.name.icontains(search))
    return query.limit(limit).offset(offset).all()


@router.get("/{stadium_id}", response_model=StadiumSchema)
def get_stadium(stadium_id: str, db: Session = Depends(get_db)):
    return db.query(Stadium).filter(Stadium.id == stadium_id).first()
