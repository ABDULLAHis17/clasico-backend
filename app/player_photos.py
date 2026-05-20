"""
Resolve player photo URLs and ratings.

Since seed_v2 stores CDN photo URLs and ratings directly in the MySQL database,
the complex JSON-based lookup is no longer needed at runtime.
These functions are kept for backward compatibility with routers that call them.
"""


def get_photo_url(player_name: str, fallback: str = '') -> str:
    """Return fallback — photo URLs are now stored directly in the DB."""
    return fallback


def get_rating(player_name: str, fallback: float = 0.0) -> float:
    """Return fallback — ratings are now stored directly in the DB as market_value."""
    return fallback
