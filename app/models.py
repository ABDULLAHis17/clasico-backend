from sqlalchemy import Column, Integer, String, Text, Boolean, TIMESTAMP, ForeignKey, JSON, Enum, Float, Date, PrimaryKeyConstraint, Index
from sqlalchemy.orm import relationship
from sqlalchemy.sql import func
import enum
from .database import Base

# --- ENUMS ---
class FriendshipStatus(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    blocked = "blocked"

class FriendRequestStatus(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"

class ParticipantRole(enum.Enum):
    admin = "admin"
    member = "member"

class MessageType(enum.Enum):
    text = "text"
    image = "image"
    system = "system"

class NotificationType(enum.Enum):
    match = "match"
    news = "news"
    transfer = "transfer"
    message = "message"
    game_invite = "game_invite"
    custom = "custom"

class EntityType(enum.Enum):
    match = "match"
    news = "news"
    transfer = "transfer"
    club = "club"
    player = "player"

class ModerationAction(enum.Enum):
    allow = "allow"
    delete = "delete"
    ban = "ban"

class ModerationChecker(enum.Enum):
    ai = "ai"
    mod = "mod"

class TeamType(enum.Enum):
    club = "club"
    national = "national"

class MatchStatus(enum.Enum):
    scheduled = "scheduled"
    live = "live"
    finished = "finished"

class MatchEventType(enum.Enum):
    goal = "goal"
    card = "card"
    substitution = "substitution"
    var = "var"

class InjuryStatus(enum.Enum):
    active = "active"
    recovered = "recovered"

class TransferType(enum.Enum):
    loan = "loan"
    permanent = "permanent"
    free = "free"

class GameMode(enum.Enum):
    offline = "offline"
    online = "online"

class GameStatus(enum.Enum):
    active = "active"
    finished = "finished"
    cancelled = "cancelled"

class GamePlayerRole(enum.Enum):
    host = "host"
    opponent = "opponent"
    cpu = "cpu"

class InviteStatus(enum.Enum):
    pending = "pending"
    accepted = "accepted"
    rejected = "rejected"
    expired = "expired"

class AISource(enum.Enum):
    ai = "ai"
    manual = "manual"

class AICategory(enum.Enum):
    translation = "translation"
    moderation = "moderation"
    generation = "generation"


# --- 1) Accounts and Profile ---

class User(Base):
    __tablename__ = 'users'
    id = Column(String(50), primary_key=True)  # Using String for UUIDs or external IDs
    email = Column(String(255), unique=True, nullable=False)
    provider = Column(String(50))
    provider_user_id = Column(String(255))
    status = Column(String(50), default='active')
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    hashed_password = Column(String(255), nullable=True) # Added for JWT Auth
    profile = relationship("UserProfile", back_populates="user", uselist=False)
    roles = relationship("Role", secondary="user_roles", back_populates="users")

class UserProfile(Base):
    __tablename__ = 'user_profiles'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    display_name = Column(String(100))
    avatar_url = Column(Text)
    bio = Column(Text)
    country = Column(String(100))
    city = Column(String(100))
    birthdate = Column(Date)
    gender = Column(String(20))
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    
    user = relationship("User", back_populates="profile")

class UserSettings(Base):
    __tablename__ = 'user_settings'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    language_code = Column(String(10), default='ar')
    theme_mode = Column(String(20), default='system')
    notifications_enabled = Column(Boolean, default=True)
    use_24h_time = Column(Boolean, default=True)
    microphone_enabled = Column(Boolean, default=True)
    location_enabled = Column(Boolean, default=False)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

class UserDevice(Base):
    __tablename__ = 'user_devices'
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    platform = Column(String(50))
    device_model = Column(String(100))
    push_token = Column(Text)
    last_seen_at = Column(TIMESTAMP)
    created_at = Column(TIMESTAMP, server_default=func.now())

# --- 1.1) RBAC & Permissions ---

class Role(Base):
    __tablename__ = 'roles'
    id = Column(Integer, primary_key=True, autoincrement=True)
    name = Column(String(50), unique=True, nullable=False) # user, moderator, admin
    description = Column(String(255))
    
    users = relationship("User", secondary="user_roles", back_populates="roles")

class UserRole(Base):
    __tablename__ = 'user_roles'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    role_id = Column(Integer, ForeignKey('roles.id', ondelete='CASCADE'), primary_key=True)

class Ban(Base):
    __tablename__ = 'bans'
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    admin_id = Column(String(50), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    type = Column(String(50))         # temporary | permanent | game-only
    ban_scope = Column(String(50), default='full')  # full | game-only
    reason = Column(Text)
    expires_at = Column(TIMESTAMP, nullable=True)
    is_active = Column(Boolean, default=True)       # soft deactivation on unban
    created_at = Column(TIMESTAMP, server_default=func.now())
    ip_address = Column(String(50), nullable=True)  # Added for IP Banning
    metadata_json = Column(JSON)      # e.g. {"game_code": "trivia"} for game-only bans

    __table_args__ = (Index('ix_bans_user_id_is_active', 'user_id', 'is_active'),)

class Report(Base):
    __tablename__ = 'reports'
    id = Column(Integer, primary_key=True, autoincrement=True)
    reporter_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    target_id = Column(String(50)) # Can be user_id or comment_id
    entity_type = Column(String(50)) # user, comment
    reason = Column(Text)
    status = Column(String(50), default='pending') # pending, resolved, rejected
    toxicity_score = Column(Float, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())
    resolved_at = Column(TIMESTAMP, nullable=True)
    resolved_by = Column(String(50), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)

# --- 2) Social & Messaging ---

class Friend(Base):
    __tablename__ = 'friends'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    friend_user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    status = Column(Enum(FriendshipStatus), default=FriendshipStatus.pending)
    created_at = Column(TIMESTAMP, server_default=func.now())

class FriendRequest(Base):
    __tablename__ = 'friend_requests'
    id = Column(Integer, primary_key=True, autoincrement=True)
    from_user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    to_user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    status = Column(Enum(FriendRequestStatus), default=FriendRequestStatus.pending)
    created_at = Column(TIMESTAMP, server_default=func.now())

class UserBlock(Base):
    __tablename__ = 'user_blocks'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    blocked_user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

class Conversation(Base):
    __tablename__ = 'conversations'
    id = Column(String(50), primary_key=True)
    is_group = Column(Boolean, default=False)
    title = Column(String(255))
    created_at = Column(TIMESTAMP, server_default=func.now())
    created_by_user_id = Column(String(50), ForeignKey('users.id'))

class ConversationParticipant(Base):
    __tablename__ = 'conversation_participants'
    conversation_id = Column(String(50), ForeignKey('conversations.id', ondelete='CASCADE'), primary_key=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    joined_at = Column(TIMESTAMP, server_default=func.now())
    role = Column(Enum(ParticipantRole), default=ParticipantRole.member)

class Message(Base):
    __tablename__ = 'messages'
    id = Column(String(50), primary_key=True)
    conversation_id = Column(String(50), ForeignKey('conversations.id', ondelete='CASCADE'))
    sender_user_id = Column(String(50), ForeignKey('users.id', ondelete='SET NULL'))
    type = Column(Enum(MessageType), default=MessageType.text)
    content = Column(Text)
    language = Column(String(10))
    translated_content = Column(Text)
    metadata_json = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())
    edited_at = Column(TIMESTAMP)
    deleted_at = Column(TIMESTAMP)
    
    __table_args__ = (Index('ix_messages_conversation_id_created_at', 'conversation_id', 'created_at'),)

class MessageReaction(Base):
    __tablename__ = 'message_reactions'
    message_id = Column(String(50), ForeignKey('messages.id', ondelete='CASCADE'), primary_key=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    emoji = Column(String(10))
    created_at = Column(TIMESTAMP, server_default=func.now())

# --- 3) Notifications ---

class Notification(Base):
    __tablename__ = 'notifications'
    id = Column(String(50), primary_key=True)
    type = Column(Enum(NotificationType))
    title = Column(String(255))
    body = Column(Text)
    payload_json = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())

class UserNotification(Base):
    __tablename__ = 'user_notifications'
    notification_id = Column(String(50), ForeignKey('notifications.id', ondelete='CASCADE'), primary_key=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    delivered_at = Column(TIMESTAMP)
    read_at = Column(TIMESTAMP)
    actioned_at = Column(TIMESTAMP)

# --- 4) Comments & Moderation ---

class Comment(Base):
    __tablename__ = 'comments'
    id = Column(String(50), primary_key=True)
    entity_type = Column(Enum(EntityType))
    entity_id = Column(String(50))
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    content = Column(Text)
    language = Column(String(10))
    translated_content = Column(Text)
    parent_comment_id = Column(String(50), ForeignKey('comments.id', ondelete='CASCADE'), nullable=True)
    likes_count = Column(Integer, default=0)
    is_hidden = Column(Boolean, default=False)          # admin-hidden flag
    report_count = Column(Integer, default=0)           # cached report count
    toxicity_score = Column(Float, nullable=True)       # AI toxicity score (0.0 – 1.0)
    created_at = Column(TIMESTAMP, server_default=func.now())
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())
    deleted_at = Column(TIMESTAMP)

    __table_args__ = (
        Index('ix_comments_entity_type_entity_id_created_at', 'entity_type', 'entity_id', 'created_at'),
        Index('ix_comments_is_hidden_report_count', 'is_hidden', 'report_count'),
    )

class CommentLike(Base):
    __tablename__ = 'comment_likes'
    comment_id = Column(String(50), ForeignKey('comments.id', ondelete='CASCADE'), primary_key=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

class CommentTranslation(Base):
    __tablename__ = 'comment_translations'
    id = Column(Integer, primary_key=True, autoincrement=True)
    comment_id = Column(String(50), ForeignKey('comments.id', ondelete='CASCADE'))
    language = Column(String(10))
    translated_text = Column(Text)
    created_at = Column(TIMESTAMP, server_default=func.now())

class CommentModerationLog(Base):
    __tablename__ = 'comment_moderation_logs'
    id = Column(Integer, primary_key=True, autoincrement=True)
    comment_id = Column(String(50), ForeignKey('comments.id', ondelete='CASCADE'))
    checked_by = Column(Enum(ModerationChecker))
    action = Column(Enum(ModerationAction))
    reason = Column(Text)
    ai_score = Column(Float)
    raw_result_json = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())

# --- 5) Favorites ---

class FavoriteMatch(Base):
    __tablename__ = 'favorite_matches'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    match_id = Column(String(50), ForeignKey('matches.id', ondelete='CASCADE'), primary_key=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

class FavoriteTeam(Base):
    __tablename__ = 'favorite_teams'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    team_id = Column(String(50), ForeignKey('teams.id', ondelete='CASCADE'), primary_key=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

class FavoritePlayer(Base):
    __tablename__ = 'favorite_players'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    player_id = Column(String(50), ForeignKey('players.id', ondelete='CASCADE'), primary_key=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

class FavoriteLeague(Base):
    __tablename__ = 'favorite_leagues'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    league_id = Column(String(50), ForeignKey('leagues.id', ondelete='CASCADE'), primary_key=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

# --- 6) Football Domain ---

class League(Base):
    __tablename__ = 'leagues'
    id = Column(String(50), primary_key=True)
    name = Column(String(255))
    country = Column(String(100))
    logo_url = Column(Text)
    level = Column(Integer)
    created_at = Column(TIMESTAMP, server_default=func.now())

    matches = relationship("Match", back_populates="league", foreign_keys="Match.league_id")

class Season(Base):
    __tablename__ = 'seasons'
    id = Column(String(50), primary_key=True)
    league_id = Column(String(50), ForeignKey('leagues.id', ondelete='RESTRICT'))
    name = Column(String(100))
    year_start = Column(Integer)
    year_end = Column(Integer)
    created_at = Column(TIMESTAMP, server_default=func.now())

class Team(Base):
    __tablename__ = 'teams'
    id = Column(String(50), primary_key=True)
    league_id = Column(String(50), ForeignKey('leagues.id', ondelete='RESTRICT'), nullable=True)
    name = Column(String(255))
    short_name = Column(String(50))
    type = Column(Enum(TeamType), default=TeamType.club)
    country = Column(String(100))
    founded_year = Column(Integer)
    logo_url = Column(Text)
    stadium_id = Column(String(50), ForeignKey('stadiums.id', ondelete='SET NULL'), nullable=True)
    cups = Column(Text, nullable=True)       # JSON: trophy names -> {text: count, link: url}
    cups_date = Column(Text, nullable=True)   # JSON: [{label, text: year, link}]
    created_at = Column(TIMESTAMP, server_default=func.now())

    home_matches = relationship("Match", back_populates="home_team", foreign_keys="Match.home_team_id")
    away_matches = relationship("Match", back_populates="away_team", foreign_keys="Match.away_team_id")

class Stadium(Base):
    __tablename__ = 'stadiums'
    id = Column(String(50), primary_key=True)
    name = Column(String(255))
    city = Column(String(100))
    country = Column(String(100))
    capacity = Column(Integer)
    built_year = Column(Integer)
    image_url = Column(Text)

class Coach(Base):
    __tablename__ = 'coaches'
    id = Column(String(50), primary_key=True)
    team_id = Column(String(50), ForeignKey('teams.id', ondelete='CASCADE'))
    name = Column(String(255))
    nationality = Column(String(100))
    birthdate = Column(Date)
    photo_url = Column(Text)
    start_date = Column(Date)
    end_date = Column(Date, nullable=True)

class Player(Base):
    __tablename__ = 'players'
    id = Column(String(50), primary_key=True)
    team_id = Column(String(50), ForeignKey('teams.id', ondelete='SET NULL'), nullable=True)
    name = Column(String(255))
    position = Column(String(50))
    shirt_number = Column(Integer)
    nationality = Column(String(100))
    birthdate = Column(Date)
    age = Column(Integer)
    height_cm = Column(Integer)
    weight_kg = Column(Integer)
    photo_url = Column(Text)
    market_value = Column(Float)
    preferred_foot = Column(String(50))
    career_history = Column(JSON, nullable=True)
    created_at = Column(TIMESTAMP, server_default=func.now())

class Match(Base):
    __tablename__ = 'matches'
    id = Column(String(50), primary_key=True)
    league_id = Column(String(50), ForeignKey('leagues.id', ondelete='RESTRICT'))
    season_id = Column(String(50), ForeignKey('seasons.id', ondelete='RESTRICT'), nullable=True)
    round = Column(String(50))
    match_date = Column(TIMESTAMP)
    status = Column(Enum(MatchStatus), default=MatchStatus.scheduled)
    venue_id = Column(String(50), ForeignKey('stadiums.id', ondelete='SET NULL'), nullable=True)
    referee = Column(String(255))
    attendance = Column(Integer)
    home_team_id = Column(String(50), ForeignKey('teams.id', ondelete='RESTRICT'))
    away_team_id = Column(String(50), ForeignKey('teams.id', ondelete='RESTRICT'))
    home_score = Column(Integer, default=0)
    away_score = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.now())

    league = relationship("League", back_populates="matches", foreign_keys=[league_id])
    home_team = relationship("Team", back_populates="home_matches", foreign_keys=[home_team_id])
    away_team = relationship("Team", back_populates="away_matches", foreign_keys=[away_team_id])

    __table_args__ = (Index('ix_matches_league_id_match_date', 'league_id', 'match_date'),)

class Lineup(Base):
    __tablename__ = 'lineups'
    id = Column(Integer, primary_key=True, autoincrement=True)
    match_id = Column(String(50), ForeignKey('matches.id', ondelete='CASCADE'))
    team_id = Column(String(50), ForeignKey('teams.id', ondelete='CASCADE'))
    formation = Column(String(20))
    lineup_json = Column(JSON)
    bench_json = Column(JSON)

class MatchEvent(Base):
    __tablename__ = 'match_events'
    id = Column(Integer, primary_key=True, autoincrement=True)
    match_id = Column(String(50), ForeignKey('matches.id', ondelete='CASCADE'))
    minute = Column(Integer)
    extra_minute = Column(Integer, nullable=True)
    event_type = Column(Enum(MatchEventType))
    team_id = Column(String(50), ForeignKey('teams.id', ondelete='CASCADE'))
    player_id = Column(String(50), ForeignKey('players.id', ondelete='CASCADE'))
    assist_player_id = Column(String(50), ForeignKey('players.id', ondelete='SET NULL'), nullable=True)
    details_json = Column(JSON)

class MatchStatistic(Base):
    __tablename__ = 'match_statistics'
    id = Column(Integer, primary_key=True, autoincrement=True)
    match_id = Column(String(50), ForeignKey('matches.id', ondelete='CASCADE'))
    team_id = Column(String(50), ForeignKey('teams.id', ondelete='CASCADE'))
    shots = Column(Integer, default=0)
    shots_on_target = Column(Integer, default=0)
    possession_pct = Column(Float, default=0)
    passes = Column(Integer, default=0)
    pass_accuracy_pct = Column(Float, default=0)
    fouls = Column(Integer, default=0)
    yellow_cards = Column(Integer, default=0)
    red_cards = Column(Integer, default=0)
    offsides = Column(Integer, default=0)
    corners = Column(Integer, default=0)
    saves = Column(Integer, default=0)
    created_at = Column(TIMESTAMP, server_default=func.now())

class Injury(Base):
    __tablename__ = 'injuries'
    id = Column(Integer, primary_key=True, autoincrement=True)
    player_id = Column(String(50), ForeignKey('players.id', ondelete='CASCADE'))
    description = Column(Text)
    start_date = Column(Date)
    expected_return_date = Column(Date, nullable=True)
    status = Column(Enum(InjuryStatus), default=InjuryStatus.active)
    created_at = Column(TIMESTAMP, server_default=func.now())

class Transfer(Base):
    __tablename__ = 'transfers'
    id = Column(Integer, primary_key=True, autoincrement=True)
    player_id = Column(String(50), ForeignKey('players.id', ondelete='CASCADE'))
    from_team_id = Column(String(50), ForeignKey('teams.id', ondelete='SET NULL'), nullable=True)
    to_team_id = Column(String(50), ForeignKey('teams.id', ondelete='CASCADE'))
    fee_currency = Column(String(20))
    fee_amount = Column(Float)
    transfer_type = Column(Enum(TransferType))
    transfer_date = Column(Date)
    source_url = Column(Text)

class LeagueStanding(Base):
    __tablename__ = 'league_standings'
    id = Column(Integer, primary_key=True, autoincrement=True)
    league_id = Column(String(50), ForeignKey('leagues.id', ondelete='CASCADE'))
    season_id = Column(String(50), ForeignKey('seasons.id', ondelete='CASCADE'))
    team_id = Column(String(50), ForeignKey('teams.id', ondelete='CASCADE'))
    position = Column(Integer)
    played = Column(Integer, default=0)
    won = Column(Integer, default=0)
    drawn = Column(Integer, default=0)
    lost = Column(Integer, default=0)
    goals_for = Column(Integer, default=0)
    goals_against = Column(Integer, default=0)
    goal_diff = Column(Integer, default=0)
    points = Column(Integer, default=0)
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

class LeagueStatistic(Base):
    __tablename__ = 'league_statistics'
    id = Column(Integer, primary_key=True, autoincrement=True)
    league_id = Column(String(50), ForeignKey('leagues.id', ondelete='CASCADE'))
    season_id = Column(String(50), ForeignKey('seasons.id', ondelete='CASCADE'))
    top_scorer_player_id = Column(String(50), ForeignKey('players.id', ondelete='SET NULL'), nullable=True)
    top_assist_player_id = Column(String(50), ForeignKey('players.id', ondelete='SET NULL'), nullable=True)
    clean_sheets_leader_player_id = Column(String(50), ForeignKey('players.id', ondelete='SET NULL'), nullable=True)
    data_json = Column(JSON)
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

class News(Base):
    __tablename__ = 'news'
    id = Column(String(50), primary_key=True)
    title = Column(String(255))
    summary = Column(Text)
    content = Column(Text)
    language = Column(String(10))
    source = Column(String(100))
    url = Column(Text)
    image_url = Column(Text)
    published_at = Column(TIMESTAMP)
    league_id = Column(String(50), ForeignKey('leagues.id', ondelete='SET NULL'), nullable=True)
    team_id = Column(String(50), ForeignKey('teams.id', ondelete='SET NULL'), nullable=True)
    player_id = Column(String(50), ForeignKey('players.id', ondelete='SET NULL'), nullable=True)

# --- 7) Games & Multiplayer ---

class Game(Base):
    __tablename__ = 'games'
    code = Column(String(50), primary_key=True)
    name = Column(String(255))
    description = Column(Text)
    supports_online = Column(Boolean, default=False)

class GameSession(Base):
    __tablename__ = 'game_sessions'
    id = Column(String(50), primary_key=True)
    game_code = Column(String(50), ForeignKey('games.code', ondelete='CASCADE'))
    mode = Column(Enum(GameMode))
    status = Column(Enum(GameStatus), default=GameStatus.active)
    created_by_user_id = Column(String(50), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    started_at = Column(TIMESTAMP)
    ended_at = Column(TIMESTAMP, nullable=True)
    settings_json = Column(JSON)

class GameSessionPlayer(Base):
    __tablename__ = 'game_session_players'
    session_id = Column(String(50), ForeignKey('game_sessions.id', ondelete='CASCADE'), primary_key=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    role = Column(Enum(GamePlayerRole))
    score = Column(Integer, default=0)
    is_winner = Column(Boolean, default=False)

class GameRound(Base):
    __tablename__ = 'game_rounds'
    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String(50), ForeignKey('game_sessions.id', ondelete='CASCADE'))
    round_index = Column(Integer)
    question_id = Column(Integer, ForeignKey('ai_questions.id', ondelete='SET NULL'), nullable=True)
    prompt_hash = Column(String(255), nullable=True)
    result_json = Column(JSON)
    started_at = Column(TIMESTAMP)
    ended_at = Column(TIMESTAMP, nullable=True)

class GameMove(Base):
    __tablename__ = 'game_moves'
    id = Column(Integer, primary_key=True, autoincrement=True)
    session_id = Column(String(50), ForeignKey('game_sessions.id', ondelete='CASCADE'))
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    action_type = Column(String(100))
    payload_json = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())

class GameInvite(Base):
    __tablename__ = 'game_invites'
    id = Column(Integer, primary_key=True, autoincrement=True)
    from_user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    to_user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    game_code = Column(String(50), ForeignKey('games.code', ondelete='CASCADE'))
    session_id = Column(String(50), ForeignKey('game_sessions.id', ondelete='SET NULL'), nullable=True)
    status = Column(Enum(InviteStatus), default=InviteStatus.pending)
    created_at = Column(TIMESTAMP, server_default=func.now())

class UserBestScore(Base):
    __tablename__ = 'user_best_scores'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    game_code = Column(String(50), ForeignKey('games.code', ondelete='CASCADE'), primary_key=True)
    best_score = Column(Integer, default=0)
    achieved_at = Column(TIMESTAMP, server_default=func.now())

class Achievement(Base):
    __tablename__ = 'achievements'
    id = Column(Integer, primary_key=True, autoincrement=True)
    game_code = Column(String(50), ForeignKey('games.code', ondelete='CASCADE'))
    code = Column(String(100), unique=True)
    name = Column(String(255))
    description = Column(Text)
    criteria_json = Column(JSON)

class UserAchievement(Base):
    __tablename__ = 'user_achievements'
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'), primary_key=True)
    achievement_id = Column(Integer, ForeignKey('achievements.id', ondelete='CASCADE'), primary_key=True)
    unlocked_at = Column(TIMESTAMP, server_default=func.now())

class MatchmakingQueue(Base):
    __tablename__ = 'matchmaking_queue'
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='CASCADE'))
    game_code = Column(String(50), ForeignKey('games.code', ondelete='CASCADE'))
    region = Column(String(50))
    mmr = Column(Integer, default=1000)
    enqueued_at = Column(TIMESTAMP, server_default=func.now())

# --- 8) AI & Content ---

class AIQuestion(Base):
    __tablename__ = 'ai_questions'
    id = Column(Integer, primary_key=True, autoincrement=True)
    game_code = Column(String(50), ForeignKey('games.code', ondelete='CASCADE'))
    language = Column(String(10))
    prompt = Column(Text)
    prompt_hash = Column(String(255), unique=True)
    question_text = Column(Text)
    options_json = Column(JSON)
    correct_answer = Column(String(255))
    difficulty = Column(String(50))
    source = Column(Enum(AISource), default=AISource.ai)
    cached_at = Column(TIMESTAMP, server_default=func.now())

class AIPromptCache(Base):
    __tablename__ = 'ai_prompt_cache'
    id = Column(Integer, primary_key=True, autoincrement=True)
    category = Column(Enum(AICategory))
    input_hash = Column(String(255), unique=True)
    input_text = Column(Text)
    output_text = Column(Text)
    meta_json = Column(JSON)
    created_at = Column(TIMESTAMP, server_default=func.now())

class TranslationLog(Base):
    __tablename__ = 'translation_logs'
    id = Column(Integer, primary_key=True, autoincrement=True)
    user_id = Column(String(50), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    source_lang = Column(String(10))
    target_lang = Column(String(10))
    input_len = Column(Integer)
    success = Column(Boolean, default=True)
    latency_ms = Column(Integer)
    created_at = Column(TIMESTAMP, server_default=func.now())

# --- 9) Admin & System ---

class AppSetting(Base):
    __tablename__ = 'app_settings'
    key = Column(String(100), primary_key=True)
    value = Column(Text)
    updated_at = Column(TIMESTAMP, server_default=func.now(), onupdate=func.now())

class AuditLog(Base):
    __tablename__ = 'audit_logs'
    id = Column(Integer, primary_key=True, autoincrement=True)
    admin_id = Column(String(50), ForeignKey('users.id', ondelete='SET NULL'), nullable=True)
    action = Column(String(100), nullable=False)
    target_id = Column(String(50))
    target_type = Column(String(50))   # user | comment | report | notification
    metadata_json = Column(JSON)
    ip_address = Column(String(50), nullable=True)
    timestamp = Column(TIMESTAMP, server_default=func.now())

    __table_args__ = (Index('ix_audit_logs_admin_id_timestamp', 'admin_id', 'timestamp'),)
