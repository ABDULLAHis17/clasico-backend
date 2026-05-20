from fastapi import APIRouter, Depends
from sqlalchemy.orm import Session

from ..database import get_db
from ..models import Coach
from ..schemas import CoachSchema

router = APIRouter(prefix="/coaches", tags=["Coaches"])

@router.get("/", response_model=list[CoachSchema])
def get_coaches(
    search: str | None = None,
    limit: int = 50,
    offset: int = 0,
    db: Session = Depends(get_db)
):
    query = db.query(Coach)
    if search:
        query = query.filter(Coach.name.icontains(search))
    return query.limit(limit).offset(offset).all()


@router.get("/{coach_id}", response_model=CoachSchema)
def get_coach(coach_id: str, db: Session = Depends(get_db)):
    return db.query(Coach).filter(Coach.id == coach_id).first()
