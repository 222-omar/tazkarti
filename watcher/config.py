import os
from dataclasses import dataclass, field
from typing import List, Dict, Any

# ==============================================================================
# TAZKARTI CONFIGURATION
# ==============================================================================
TAZKARTI_BASE_URL = "https://tazkarti.com/"
TAZKARTI_MATCHES_URL = "https://tazkarti.com/data/matches-list-json.json"

DEFAULT_HEADERS = {
    "Accept": "application/json",
    "Referer": "https://tazkarti.com/",
    "User-Agent": (
        "Mozilla/5.0 (Windows NT 10.0; Win64; x64) "
        "AppleWebKit/537.36 (KHTML, like Gecko) "
        "Chrome/125.0.0.0 Safari/537.36"
    ),
}

# ==============================================================================
# TRACKED TEAMS CONFIGURATION (Config-driven, easily extensible)
# ==============================================================================
TRACKED_TEAMS: List[Dict[str, Any]] = [
    {
        "key": "ahly",
        "topic": "ahly_tickets",
        "display_ar": "الأهلي",
        "team_ids": [],  # TODO: Populate with official teamId once an Ahly match is listed
        "aliases": [
            "الأهلي",
            "الاهلي",
            "النادي الأهلي",
            "النادي الاهلي",
            "Al Ahly",
            "Al-Ahly",
            "Ahly",
            "Al Ahly FC",
        ],
    },
    {
        "key": "egypt",
        "topic": "egypt_tickets",
        "display_ar": "منتخب مصر",
        # teamId1=122 in the sample match Egypt vs South Africa, but matches tournament id 122.
        # Leave empty until verified against multiple matches.
        "team_ids": [],
        "aliases": [
            "مصر",
            "منتخب مصر",
            "Egypt",
            "Egypt National Team",
        ],
    },
]

# High importance notification channel for Android 8.0+
ANDROID_NOTIFICATION_CHANNEL_ID = "tickets_high"
ADMIN_ALERTS_TOPIC = "admin_alerts"


@dataclass
class Settings:
    # Mode flags
    mock_mode: bool = field(
        default_factory=lambda: os.getenv("MOCK", "0").lower() in ("1", "true", "yes")
    )
    seed_silently: bool = field(
        default_factory=lambda: os.getenv("SEED_SILENTLY", "true").lower() in ("1", "true", "yes")
    )

    # Polling & Reliability
    request_timeout_seconds: float = 15.0
    failure_alert_threshold: int = field(
        default_factory=lambda: int(os.getenv("FAILURE_ALERT_THRESHOLD", "5"))
    )
    admin_topic: str = field(
        default_factory=lambda: os.getenv("ADMIN_TOPIC", ADMIN_ALERTS_TOPIC)
    )

    # Server config
    port: int = field(
        default_factory=lambda: int(os.getenv("PORT", "8080"))
    )
    firestore_collection: str = "matches"
    watcher_state_collection: str = "watcher_state"


settings = Settings()
