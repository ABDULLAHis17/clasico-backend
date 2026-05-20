from fastapi import APIRouter, Depends, Query
from sqlalchemy.orm import Session
from typing import List, Optional

from ..database import get_db
from ..models import News
from ..schemas import NewsSchema

router = APIRouter(prefix="/news", tags=["News"])


@router.get("/", response_model=List[NewsSchema])
def get_news(
    league_id: Optional[str] = Query(None),
    db: Session = Depends(get_db)
):
    query = db.query(News).order_by(News.published_at.desc())
    if league_id:
        query = query.filter(News.league_id == league_id)
    return query.all()


@router.get("/{news_id}", response_model=NewsSchema)
def get_news_item(news_id: str, db: Session = Depends(get_db)):
    return db.query(News).filter(News.id == news_id).first()
