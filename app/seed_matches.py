import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timedelta
from app.database import SessionLocal
from app import models
from app.models import Match, MatchStatus

def seed_matches_only():
    db = SessionLocal()
    try:
        if db.query(Match).count() > 0:
            print("Deleting old matches...")
            db.query(Match).delete()
            db.commit()

        print("Seeding matches...")
        now = datetime.utcnow()
        matches = [
            # Premier League - Upcoming
            Match(id='m1',  league_id='1', home_team_id='t1',  away_team_id='t2',  match_date=now + timedelta(hours=3),  status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m2',  league_id='1', home_team_id='t3',  away_team_id='t4',  match_date=now + timedelta(hours=5),  status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m3',  league_id='1', home_team_id='t5',  away_team_id='t6',  match_date=now + timedelta(days=1, hours=2), status=MatchStatus.scheduled, home_score=0, away_score=0),
            # Premier League - Finished
            Match(id='m4',  league_id='1', home_team_id='t6',  away_team_id='t9',  match_date=now - timedelta(days=1),  status=MatchStatus.finished,   home_score=2, away_score=1),
            Match(id='m5',  league_id='1', home_team_id='t7',  away_team_id='t8',  match_date=now - timedelta(hours=12), status=MatchStatus.finished,   home_score=3, away_score=2),
            # La Liga
            Match(id='m6',  league_id='2', home_team_id='t10', away_team_id='t11', match_date=now + timedelta(hours=4),  status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m7',  league_id='2', home_team_id='t12', away_team_id='t13', match_date=now + timedelta(days=1, hours=3), status=MatchStatus.scheduled, home_score=0, away_score=0),
            # Serie A
            Match(id='m8',  league_id='3', home_team_id='t14', away_team_id='t15', match_date=now + timedelta(hours=6),  status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m9',  league_id='3', home_team_id='t16', away_team_id='t17', match_date=now + timedelta(days=1, hours=4), status=MatchStatus.scheduled, home_score=0, away_score=0),
            # Bundesliga
            Match(id='m10', league_id='4', home_team_id='t18', away_team_id='t19', match_date=now + timedelta(hours=2),  status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m11', league_id='4', home_team_id='t20', away_team_id='t21', match_date=now + timedelta(days=1, hours=5), status=MatchStatus.scheduled, home_score=0, away_score=0),
            # Ligue 1
            Match(id='m12', league_id='5', home_team_id='t22', away_team_id='t23', match_date=now + timedelta(hours=7),  status=MatchStatus.scheduled, home_score=0, away_score=0),
            # European
            Match(id='m13', league_id='6', home_team_id='t10', away_team_id='t5',  match_date=now + timedelta(hours=8),  status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m14', league_id='6', home_team_id='t18', away_team_id='t22', match_date=now + timedelta(days=1, hours=6), status=MatchStatus.scheduled, home_score=0, away_score=0),
            # National
            Match(id='m15', league_id='7', home_team_id='t32', away_team_id='t33', match_date=now + timedelta(hours=10), status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m16', league_id='7', home_team_id='t34', away_team_id='t35', match_date=now + timedelta(days=2, hours=2), status=MatchStatus.scheduled, home_score=0, away_score=0),
            # Saudi Pro League
            Match(id='m17', league_id='8', home_team_id='t24', away_team_id='t25', match_date=now + timedelta(hours=9),  status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m18', league_id='8', home_team_id='t26', away_team_id='t27', match_date=now + timedelta(days=1, hours=7), status=MatchStatus.scheduled, home_score=0, away_score=0),
            # Turkish
            Match(id='m19', league_id='9', home_team_id='t28', away_team_id='t29', match_date=now + timedelta(hours=11), status=MatchStatus.scheduled, home_score=0, away_score=0),
            Match(id='m20', league_id='9', home_team_id='t30', away_team_id='t31', match_date=now + timedelta(days=1, hours=8), status=MatchStatus.scheduled, home_score=0, away_score=0),
        ]
        db.add_all(matches)
        db.commit()
        print("✅ Mock matches seeded successfully!")
    except Exception as e:
        db.rollback()
        print(f"❌ Failed: {e}")
    finally:
        db.close()

if __name__ == "__main__":
    seed_matches_only()
