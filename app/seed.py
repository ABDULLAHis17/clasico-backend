"""
Seed script: inserts the initial mock data (from sample_data.dart) into MySQL.
This is called automatically at startup by main.py if the database is empty.
"""
import sys
import os
sys.path.insert(0, os.path.dirname(os.path.dirname(os.path.abspath(__file__))))

from datetime import datetime, timedelta
from app.database import SessionLocal
from app import models
from app.models import League, Team, Player, Match, News, MatchStatus


def seed():
    db = SessionLocal()
    try:
        # ── Roles ─────────────────────────────────────────────────────────────
        roles = [
            models.Role(name="user", description="Default user role"),
            models.Role(name="moderator", description="Can moderate content"),
            models.Role(name="admin", description="Full system access"),
        ]
        for r in roles:
            existing = db.query(models.Role).filter(models.Role.name == r.name).first()
            if not existing:
                db.add(r)
        db.flush()

        # ── Admin User ────────────────────────────────────────────────────────
        from app.auth import get_password_hash
        admin_email = "admin@clasico.com"
        existing_admin = db.query(models.User).filter(models.User.email == admin_email).first()
        if not existing_admin:
            print(f"👤 Creating default admin: {admin_email}")
            admin_pw = "admin123"
            admin = models.User(
                id=admin_email,
                email=admin_email,
                hashed_password=get_password_hash(admin_pw),
                status="active"
            )
            db.add(admin)
            db.flush()
            
            # Profile
            admin_profile = models.UserProfile(
                user_id=admin.id,
                display_name="System Admin"
            )
            db.add(admin_profile)
            
            # Roles
            admin_role = db.query(models.Role).filter(models.Role.name == "admin").first()
            if admin_role:
                admin.roles.append(admin_role)
                
        db.commit()

        # Only seed the rest if empty
        if db.query(League).count() > 0 and db.query(Player).count() > 0:
            print("ℹ️  Database mock data already seeded, skipping.")
            return

        print("🌱 Seeding database with mock data...")

        # ── Leagues ──────────────────────────────────────────────────────────
        leagues = [
            League(id='1', name='Premier League',         country='England',       logo_url='⚽'),
            League(id='2', name='La Liga',                country='Spain',         logo_url='🏆'),
            League(id='3', name='Serie A',                country='Italy',         logo_url='🎯'),
            League(id='4', name='Bundesliga',             country='Germany',       logo_url='⭐'),
            League(id='5', name='Ligue 1',                country='France',        logo_url='🔵'),
            League(id='6', name='European Matches',       country='Europe',        logo_url='🌟'),
            League(id='7', name='National Team Matches',  country='International', logo_url='🏅'),
            League(id='8', name='Saudi Pro League',       country='Saudi Arabia',  logo_url='🇸🇦'),
            League(id='9', name='Turkish Süper Lig',      country='Turkey',        logo_url='🇹🇷'),
        ]
        db.add_all(leagues)
        db.flush()

        # ── Teams ─────────────────────────────────────────────────────────────
        teams = [
            Team(id='t1',  name='Manchester United',    short_name='Man Utd',   country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/7/7a/Manchester_United_FC_crest.svg/240px-Manchester_United_FC_crest.svg.png', league_id='1'),
            Team(id='t2',  name='Liverpool',            short_name='LIV',       country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/0/0c/Liverpool_FC.svg/240px-Liverpool_FC.svg.png', league_id='1'),
            Team(id='t3',  name='Chelsea',              short_name='CHE',       country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/c/cc/Chelsea_FC.svg/240px-Chelsea_FC.svg.png', league_id='1'),
            Team(id='t4',  name='Arsenal',              short_name='ARS',       country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/5/53/Arsenal_FC.svg/240px-Arsenal_FC.svg.png', league_id='1'),
            Team(id='t5',  name='Manchester City',      short_name='Man City',  country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/e/eb/Manchester_City_FC_badge.svg/240px-Manchester_City_FC_badge.svg.png', league_id='1'),
            Team(id='t6',  name='Tottenham',            short_name='TOT',       country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/b/b4/Tottenham_Hotspur.svg/240px-Tottenham_Hotspur.svg.png', league_id='1'),
            Team(id='t7',  name='Newcastle',            short_name='NEW',       country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/5/56/Newcastle_United_Logo.svg/240px-Newcastle_United_Logo.svg.png', league_id='1'),
            Team(id='t8',  name='Aston Villa',          short_name='AVL',       country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/9/9f/Aston_Villa_logo.svg/240px-Aston_Villa_logo.svg.png', league_id='1'),
            Team(id='t9',  name='Brighton',             short_name='BHA',       country='England',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/f/fd/Brighton_%26_Hove_Albion_logo.svg/240px-Brighton_%26_Hove_Albion_logo.svg.png', league_id='1'),
            Team(id='t10', name='Real Madrid',          short_name='RMA',       country='Spain',        logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/5/56/Real_Madrid_CF.svg/240px-Real_Madrid_CF.svg.png', league_id='2'),
            Team(id='t11', name='Barcelona',            short_name='BAR',       country='Spain',        logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/4/47/FC_Barcelona_%28crest%29.svg/240px-FC_Barcelona_%28crest%29.svg.png', league_id='2'),
            Team(id='t12', name='Atletico Madrid',      short_name='ATM',       country='Spain',        logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/f/f4/Atletico_Madrid_2017_logo.svg/240px-Atletico_Madrid_2017_logo.svg.png', league_id='2'),
            Team(id='t13', name='Sevilla',              short_name='SEV',       country='Spain',        logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/3/3b/Sevilla_FC_logo.svg/240px-Sevilla_FC_logo.svg.png', league_id='2'),
            Team(id='t14', name='Juventus',             short_name='JUV',       country='Italy',        logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/b/bc/Juventus_FC_-_rect_logo_%28black_bckgwnd%29.svg/240px-Juventus_FC_-_rect_logo_%28black_bckgwnd%29.svg.png', league_id='3'),
            Team(id='t15', name='AC Milan',             short_name='MIL',       country='Italy',        logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/d/d0/Logo_of_AC_Milan.svg/240px-Logo_of_AC_Milan.svg.png', league_id='3'),
            Team(id='t16', name='Inter Milan',          short_name='INT',       country='Italy',        logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/0/05/FC_Internazionale_Milano_2021.svg/240px-FC_Internazionale_Milano_2021.svg.png', league_id='3'),
            Team(id='t17', name='AS Roma',              short_name='ROM',       country='Italy',        logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/f/f7/AS_Roma_logo_%282017%29.svg/240px-AS_Roma_logo_%282017%29.svg.png', league_id='3'),
            Team(id='t18', name='Bayern Munich',        short_name='BAY',       country='Germany',      logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/1/1b/FC_Bayern_M%C3%BCnchen_logo_%282017%29.svg/240px-FC_Bayern_M%C3%BCnchen_logo_%282017%29.svg.png', league_id='4'),
            Team(id='t19', name='Borussia Dortmund',    short_name='BVB',       country='Germany',      logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/6/67/Borussia_Dortmund_logo.svg/240px-Borussia_Dortmund_logo.svg.png', league_id='4'),
            Team(id='t20', name='RB Leipzig',           short_name='RBL',       country='Germany',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/0/04/RB_Leipzig_2014_logo.svg/240px-RB_Leipzig_2014_logo.svg.png', league_id='4'),
            Team(id='t21', name='Bayer Leverkusen',     short_name='B04',       country='Germany',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/5/59/Bayer_04_Leverkusen_logo.svg/240px-Bayer_04_Leverkusen_logo.svg.png', league_id='4'),
            Team(id='t22', name='Paris Saint-Germain',  short_name='PSG',       country='France',       logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/a/a7/Paris_Saint-Germain_F.C..svg/240px-Paris_Saint-Germain_F.C..svg.png', league_id='5'),
            Team(id='t23', name='Olympique Lyon',       short_name='OL',        country='France',       logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/c/c6/Olympique_Lyonnais.svg/240px-Olympique_Lyonnais.svg.png', league_id='5'),
            Team(id='t24', name='Al-Nassr',             short_name='NAS',       country='Saudi Arabia', logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/b/b3/Al-Nassr_FC_logo.svg/240px-Al-Nassr_FC_logo.svg.png', league_id='8'),
            Team(id='t25', name='Al-Hilal',             short_name='HIL',       country='Saudi Arabia', logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/8/8c/Al_Hilal_SFC_Logo.svg/240px-Al_Hilal_SFC_Logo.svg.png', league_id='8'),
            Team(id='t26', name='Al-Ittihad',           short_name='ITT',       country='Saudi Arabia', logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/a/a4/Al_Ittihad_Jeddah_Logo.svg/240px-Al_Ittihad_Jeddah_Logo.svg.png', league_id='8'),
            Team(id='t27', name='Al-Ahli',              short_name='AHL',       country='Saudi Arabia', logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/8/87/Al-Ahli_Saudi_FC_logo.svg/240px-Al-Ahli_Saudi_FC_logo.svg.png', league_id='8'),
            Team(id='t28', name='Galatasaray',          short_name='GAL',       country='Turkey',       logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/f/f6/Galatasaray_Sports_Club_Logo.svg/240px-Galatasaray_Sports_Club_Logo.svg.png', league_id='9'),
            Team(id='t29', name='Fenerbahçe',           short_name='FEN',       country='Turkey',       logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/3/39/Fenerbah%C3%A7e.svg/240px-Fenerbah%C3%A7e.svg.png', league_id='9'),
            Team(id='t30', name='Beşiktaş',             short_name='BJK',       country='Turkey',       logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/0/08/Be%C5%9Fikta%C5%9F_Logo_Be%C5%9Fikta%C5%9F_Amblem_Be%C5%9Fikta%C5%9F_Arma.png/240px-Be%C5%9Fikta%C5%9F_Logo_Be%C5%9Fikta%C5%9F_Amblem_Be%C5%9Fikta%C5%9F_Arma.png', league_id='9'),
            Team(id='t31', name='Trabzonspor',          short_name='TS',        country='Turkey',       logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/c/ca/Trabzonspor_Amblemi.svg/240px-Trabzonspor_Amblemi.svg.png', league_id='9'),
            Team(id='t32', name='Brazil',               short_name='BRA',       country='Brazil',       logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/0/05/Flag_of_Brazil.svg/240px-Flag_of_Brazil.svg.png',  league_id='7'),
            Team(id='t33', name='Argentina',            short_name='ARG',       country='Argentina',    logo_url='https://upload.wikimedia.org/wikipedia/commons/thumb/1/1a/Flag_of_Argentina.svg/240px-Flag_of_Argentina.svg.png', league_id='7'),
            Team(id='t34', name='France',               short_name='FRA',       country='France',       logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/c/c3/Flag_of_France.svg/240px-Flag_of_France.svg.png',  league_id='7'),
            Team(id='t35', name='Germany',              short_name='GER',       country='Germany',      logo_url='https://upload.wikimedia.org/wikipedia/en/thumb/b/ba/Flag_of_Germany.svg/240px-Flag_of_Germany.svg.png', league_id='7'),
        ]
        db.add_all(teams)
        db.flush()

        # ── Players ───────────────────────────────────────────────────────────
        players = [
            # Manchester United
            Player(id='p1',  name='David De Gea',          position='GK',  shirt_number=1,  nationality='Spain',   team_id='t1',  photo_url='🧤'),
            Player(id='p2',  name='Marcus Rashford',        position='FW',  shirt_number=10, nationality='England', team_id='t1',  photo_url='⚡'),
            Player(id='p3',  name='Bruno Fernandes',        position='CM',  shirt_number=8,  nationality='Portugal',team_id='t1',  photo_url='⚙️'),
            Player(id='p4',  name='Casemiro',               position='CDM', shirt_number=18, nationality='Brazil',  team_id='t1',  photo_url='⚙️'),
            Player(id='p5',  name='Raphael Varane',         position='CB',  shirt_number=19, nationality='France',  team_id='t1',  photo_url='🛡️'),
            Player(id='p6',  name='Lisandro Martinez',      position='CB',  shirt_number=6,  nationality='Argentina',team_id='t1', photo_url='🛡️'),
            Player(id='p7',  name='Jadon Sancho',           position='LW',  shirt_number=25, nationality='England', team_id='t1',  photo_url='⚡'),
            Player(id='p8',  name='Antony',                 position='RW',  shirt_number=21, nationality='Brazil',  team_id='t1',  photo_url='⚡'),
            # Liverpool
            Player(id='p9',  name='Alisson Becker',         position='GK',  shirt_number=1,  nationality='Brazil',  team_id='t2',  photo_url='🧤'),
            Player(id='p10', name='Mohamed Salah',          position='RW',  shirt_number=11, nationality='Egypt',   team_id='t2',  photo_url='⚡'),
            Player(id='p11', name='Virgil van Dijk',        position='CB',  shirt_number=4,  nationality='Netherlands',team_id='t2',photo_url='🛡️'),
            Player(id='p12', name='Trent Alexander-Arnold', position='RB',  shirt_number=66, nationality='England', team_id='t2',  photo_url='🛡️'),
            Player(id='p13', name='Darwin Núñez',           position='ST',  shirt_number=27, nationality='Uruguay', team_id='t2',  photo_url='⚡'),
            Player(id='p14', name='Luis Díaz',              position='LW',  shirt_number=23, nationality='Colombia',team_id='t2',  photo_url='⚡'),
            # Real Madrid
            Player(id='p15', name='Thibaut Courtois',       position='GK',  shirt_number=1,  nationality='Belgium', team_id='t10', photo_url='🧤'),
            Player(id='p16', name='Vinicius Jr',            position='LW',  shirt_number=7,  nationality='Brazil',  team_id='t10', photo_url='⚡'),
            Player(id='p17', name='Jude Bellingham',        position='CM',  shirt_number=5,  nationality='England', team_id='t10', photo_url='⚙️'),
            Player(id='p18', name='Kylian Mbappé',          position='ST',  shirt_number=9,  nationality='France',  team_id='t10', photo_url='⚡'),
            Player(id='p19', name='Luka Modrić',            position='CM',  shirt_number=10, nationality='Croatia', team_id='t10', photo_url='⚙️'),
            # Barcelona
            Player(id='p20', name='Marc-André ter Stegen',  position='GK',  shirt_number=1,  nationality='Germany', team_id='t11', photo_url='🧤'),
            Player(id='p21', name='Pedri',                  position='CM',  shirt_number=8,  nationality='Spain',   team_id='t11', photo_url='⚙️'),
            Player(id='p22', name='Robert Lewandowski',     position='ST',  shirt_number=9,  nationality='Poland',  team_id='t11', photo_url='⚡'),
            Player(id='p23', name='Gavi',                   position='CM',  shirt_number=6,  nationality='Spain',   team_id='t11', photo_url='⚙️'),
            # Bayern Munich
            Player(id='p24', name='Manuel Neuer',           position='GK',  shirt_number=1,  nationality='Germany', team_id='t18', photo_url='🧤'),
            Player(id='p25', name='Harry Kane',             position='ST',  shirt_number=9,  nationality='England', team_id='t18', photo_url='⚡'),
            Player(id='p26', name='Leroy Sane',             position='LW',  shirt_number=10, nationality='Germany', team_id='t18', photo_url='⚡'),
            # PSG
            Player(id='p27', name='Gianluigi Donnarumma',   position='GK',  shirt_number=99, nationality='Italy',   team_id='t22', photo_url='🧤'),
            Player(id='p28', name='Ousmane Dembélé',        position='RW',  shirt_number=10, nationality='France',  team_id='t22', photo_url='⚡'),
            # Al-Nassr
            Player(id='p29', name='Cristiano Ronaldo',      position='ST',  shirt_number=7,  nationality='Portugal',team_id='t24', photo_url='⚡', market_value=50000000),
            Player(id='p30', name='Sadio Mané',             position='LW',  shirt_number=10, nationality='Senegal', team_id='t24', photo_url='⚡'),
            # Al-Hilal
            Player(id='p31', name='Neymar Jr',              position='LW',  shirt_number=10, nationality='Brazil',  team_id='t25', photo_url='⚡'),
            Player(id='p32', name='Kalidou Koulibaly',      position='CB',  shirt_number=3,  nationality='Senegal', team_id='t25', photo_url='🛡️'),
        ]
        db.add_all(players)
        db.flush()

        # ── Matches ───────────────────────────────────────────────────────────
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
        db.flush()

        # db.add_all(news_items) # Already in DB if seeded before

        db.commit()
        print("✅ Database seeded successfully with mock data!")

    except Exception as e:
        db.rollback()
        print(f"❌ Seeding failed: {e}")
        raise
    finally:
        db.close()


if __name__ == "__main__":
    seed()
