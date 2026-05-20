from pydantic import BaseModel, Field, field_validator
from typing import Optional, List, Any, Dict
from datetime import datetime, date


# ═══════════════════════════════════════════════════════════════
# ─── Football Domain Schemas ───────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class LeagueSchema(BaseModel):
    id: str
    name: str
    country: Optional[str] = None
    logo_url: Optional[str] = None

    model_config = {"from_attributes": True}


class TeamSchema(BaseModel):
    id: str
    name: str
    short_name: Optional[str] = None
    logo_url: Optional[str] = None
    country: Optional[str] = None
    founded_year: Optional[int] = None
    league_id: Optional[str] = None
    stadium_id: Optional[str] = None
    type: Optional[str] = None

    model_config = {"from_attributes": True}


class TeamPlayerSummary(BaseModel):
    id: str
    name: str
    position: Optional[str] = None
    shirt_number: Optional[int] = None
    nationality: Optional[str] = None
    photo_url: Optional[str] = None
    market_value: Optional[float] = None

    model_config = {"from_attributes": True}


class TeamDetailSchema(TeamSchema):
    league_name: Optional[str] = None
    league_logo: Optional[str] = None
    stadium_name: Optional[str] = None
    stadium_city: Optional[str] = None
    stadium_capacity: Optional[int] = None
    stadium_image: Optional[str] = None
    players: list[TeamPlayerSummary] = []
    squad_size: int = 0
    avg_rating: float = 0
    top_rating: float = 0


class StadiumSchema(BaseModel):
    id: str
    name: str
    city: Optional[str] = None
    country: Optional[str] = None
    capacity: Optional[int] = None
    built_year: Optional[int] = None
    image_url: Optional[str] = None

    model_config = {"from_attributes": True}


class PlayerSchema(BaseModel):
    id: str
    name: str
    position: Optional[str] = None
    shirt_number: Optional[int] = None
    nationality: Optional[str] = None
    birthdate: Optional[date] = None
    age: Optional[int] = None
    height_cm: Optional[int] = None
    weight_kg: Optional[int] = None
    photo_url: Optional[str] = None
    market_value: Optional[float] = None
    rating: Optional[float] = None
    preferred_foot: Optional[str] = None
    team_id: Optional[str] = None
    team_name: Optional[str] = None
    team_logo: Optional[str] = None

    model_config = {"from_attributes": True}


class TransferSchema(BaseModel):
    id: int
    player_id: Optional[str] = None
    from_team_id: Optional[str] = None
    to_team_id: Optional[str] = None
    from_team_name: Optional[str] = None
    from_team_logo: Optional[str] = None
    to_team_name: Optional[str] = None
    to_team_logo: Optional[str] = None
    fee_amount: Optional[float] = None
    fee_currency: Optional[str] = None
    transfer_type: Optional[str] = None
    transfer_date: Optional[date] = None

    model_config = {"from_attributes": True}


class PlayerDetailSchema(PlayerSchema):
    transfers: list[TransferSchema] = []
    skills: Optional[Dict[str, int]] = None
    career_history: Optional[Any] = None

class CoachSchema(BaseModel):
    id: str
    name: str
    team_id: Optional[str] = None
    nationality: Optional[str] = None
    photo_url: Optional[str] = None
    start_date: Optional[datetime] = None

    model_config = {"from_attributes": True}


class MatchSchema(BaseModel):
    id: str
    league_id: Optional[str] = None
    home_team_id: Optional[str] = None
    away_team_id: Optional[str] = None
    home_score: Optional[int] = 0
    away_score: Optional[int] = 0
    match_date: Optional[datetime] = None
    status: Optional[str] = None
    round: Optional[str] = None

    model_config = {"from_attributes": True}


class MatchDetailSchema(MatchSchema):
    home_team: Optional[TeamSchema] = None
    away_team: Optional[TeamSchema] = None
    league: Optional[LeagueSchema] = None


class NewsSchema(BaseModel):
    id: str
    title: Optional[str] = None
    summary: Optional[str] = None
    content: Optional[str] = None
    image_url: Optional[str] = None
    published_at: Optional[datetime] = None
    source: Optional[str] = None
    league_id: Optional[str] = None
    team_id: Optional[str] = None
    player_id: Optional[str] = None

    model_config = {"from_attributes": True}


# ═══════════════════════════════════════════════════════════════
# ─── RBAC Schemas ──────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class RoleSchema(BaseModel):
    id: int
    name: str
    description: Optional[str] = None

    model_config = {"from_attributes": True}


class UserRoleSchema(BaseModel):
    user_id: str
    role_id: int

    model_config = {"from_attributes": True}


class RoleUpdateSchema(BaseModel):
    """Input for PATCH /admin/users/{id}/role – strict typed, no mass assignment."""
    roles: List[str] = Field(..., min_length=1, description="List of role names: user | moderator | admin")

    @field_validator("roles")
    @classmethod
    def validate_roles(cls, v: List[str]) -> List[str]:
        allowed = {"user", "moderator", "admin"}
        for r in v:
            if r not in allowed:
                raise ValueError(f"Invalid role '{r}'. Allowed: {allowed}")
        return v


# ═══════════════════════════════════════════════════════════════
# ─── User Schemas ──────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class UserBaseSchema(BaseModel):
    id: str
    email: str
    provider: Optional[str] = None
    status: str = "active"

    model_config = {"from_attributes": True}


class UserProfileSchema(BaseModel):
    display_name: Optional[str] = None
    avatar_url: Optional[str] = None
    bio: Optional[str] = None
    country: Optional[str] = None
    city: Optional[str] = None
    gender: Optional[str] = None

    model_config = {"from_attributes": True}


class UserSchema(UserBaseSchema):
    roles: List[RoleSchema] = []
    created_at: datetime
    updated_at: datetime


class UserCreateSchema(BaseModel):
    email: str = Field(..., description="User email address")
    password: str = Field(..., min_length=6, max_length=100)
    display_name: Optional[str] = None


class LoginSchema(BaseModel):
    email: str
    password: str


class UserDetailSchema(UserBaseSchema):
    """Extended user view for admin – includes profile, roles, and active ban."""
    roles: List[RoleSchema] = []
    profile: Optional[UserProfileSchema] = None
    active_ban: Optional["BanSchema"] = None
    created_at: datetime
    updated_at: datetime


class TopPlayerSchema(BaseModel):
    """Top player from user_best_scores."""
    user_id: str
    display_name: Optional[str] = None
    game_code: str
    best_score: int
    achieved_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ═══════════════════════════════════════════════════════════════
# ─── Ban Schemas ───────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class BanCreateSchema(BaseModel):
    """Strict input schema for banning a user – prevents mass assignment."""
    type: str = Field(..., description="Ban type: temporary | permanent | game-only")
    reason: str = Field(..., min_length=5, max_length=1000, description="Reason for the ban")
    duration_days: Optional[int] = Field(None, ge=1, le=3650, description="Required for temporary bans")
    game_code: Optional[str] = Field(None, description="Required for game-only bans")
    ip_address: Optional[str] = Field(None, description="IP address to ban (optional, for IP-based bans)")

    @field_validator("type")
    @classmethod
    def validate_type(cls, v: str) -> str:
        allowed = {"temporary", "permanent", "game-only"}
        if v not in allowed:
            raise ValueError(f"Invalid ban type '{v}'. Allowed: {allowed}")
        return v

    @field_validator("duration_days")
    @classmethod
    def duration_required_for_temporary(cls, v, info) -> Optional[int]:
        if info.data.get("type") == "temporary" and v is None:
            raise ValueError("duration_days is required for temporary bans")
        return v


class BanSchema(BaseModel):
    id: int
    user_id: str
    admin_id: Optional[str] = None
    type: str
    ban_scope: Optional[str] = None
    reason: str
    expires_at: Optional[datetime] = None
    is_active: bool = True
    created_at: datetime
    ip_address: Optional[str] = None
    metadata_json: Optional[Dict[str, Any]] = None

    model_config = {"from_attributes": True}


# ═══════════════════════════════════════════════════════════════
# ─── Report Schemas ────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class ReportSchema(BaseModel):
    id: int
    reporter_id: str
    target_id: str
    entity_type: str
    reason: str
    status: str
    toxicity_score: Optional[float] = None
    created_at: datetime
    resolved_at: Optional[datetime] = None
    resolved_by: Optional[str] = None

    model_config = {"from_attributes": True}


class FeedbackCreateSchema(BaseModel):
    message: str = Field(..., min_length=10, max_length=2000, description="The feedback message from the user")
    email: Optional[str] = Field(None, description="Optional email for contact")


# ═══════════════════════════════════════════════════════════════
# ─── Comment Schemas ───────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class CommentDetailSchema(BaseModel):
    """Comment with admin moderation metadata."""
    id: str
    entity_type: Optional[str] = None
    entity_id: Optional[str] = None
    user_id: Optional[str] = None
    content: Optional[str] = None
    is_hidden: bool = False
    report_count: int = 0
    toxicity_score: Optional[float] = None
    likes_count: int = 0
    created_at: Optional[datetime] = None
    deleted_at: Optional[datetime] = None

    model_config = {"from_attributes": True}


# ═══════════════════════════════════════════════════════════════
# ─── Notification Schemas ──────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class NotificationBroadcastSchema(BaseModel):
    """Strict input for admin notification broadcast."""
    title: str = Field(..., min_length=1, max_length=255)
    body: str = Field(..., min_length=1, max_length=2000)
    payload: Optional[Dict[str, Any]] = None


class TeamNotificationSchema(NotificationBroadcastSchema):
    team_id: str = Field(..., description="Target team ID")


class LeagueNotificationSchema(NotificationBroadcastSchema):
    league_id: str = Field(..., description="Target league ID")


# ═══════════════════════════════════════════════════════════════
# ─── Audit Log Schemas ─────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class AuditLogSchema(BaseModel):
    id: int
    admin_id: Optional[str] = None
    action: str
    target_id: Optional[str] = None
    target_type: Optional[str] = None
    metadata_json: Optional[Dict[str, Any]] = None
    ip_address: Optional[str] = None
    timestamp: datetime

    model_config = {"from_attributes": True}


# ═══════════════════════════════════════════════════════════════
# ─── Dashboard Schemas ─────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class DashboardStatsSchema(BaseModel):
    total_users: int
    active_users: int
    banned_users: int
    online_users: int
    total_comments: int
    hidden_comments: int
    pending_reports: int
    total_reports: int
    open_bans: int


# ═══════════════════════════════════════════════════════════════
# ─── Auth Schemas ──────────────────────────────────────────────
# ═══════════════════════════════════════════════════════════════

class Token(BaseModel):
    access_token: str
    token_type: str


class TokenData(BaseModel):
    user_id: Optional[str] = None
    roles: List[str] = []


# Resolve forward refs
UserDetailSchema.model_rebuild()
