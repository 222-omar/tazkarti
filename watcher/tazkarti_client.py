import logging
import time
from datetime import datetime
from typing import List, Dict, Any, Optional
from dataclasses import dataclass, asdict
import httpx

from .config import TAZKARTI_MATCHES_URL, DEFAULT_HEADERS, TAZKARTI_BASE_URL, settings

logger = logging.getLogger("tazkarti.client")


class TazkartiValidationError(Exception):
    """Raised when the Tazkarti response does not meet structural expectations."""
    pass


class TazkartiFetchError(Exception):
    """Raised when the Tazkarti HTTP request fails or returns an error code."""
    pass


@dataclass
class Match:
    match_id: int
    team1_id: Optional[int]
    team2_id: Optional[int]
    team1_en: str
    team1_ar: str
    team2_en: str
    team2_ar: str
    kickoff: datetime
    tournament_ar: str
    tournament_en: str
    stadium_ar: str
    match_status_raw: int
    show_in_portal: bool
    is_deleted: bool
    url: str = TAZKARTI_BASE_URL
    # Extra useful context fields from Tazkarti
    stadium_en: str = ""
    team1_logo: Optional[str] = None
    team2_logo: Optional[str] = None
    max_tickets_per_user: Optional[int] = None
    gates_open_time: Optional[str] = None

    def to_dict(self) -> Dict[str, Any]:
        data = asdict(self)
        data["kickoff"] = self.kickoff.isoformat()
        return data


def _parse_iso_datetime(dt_str: Optional[str]) -> datetime:
    if not dt_str:
        return datetime.utcnow()
    try:
        # Handle ISO formatted strings e.g. "2026-10-04T21:00:00"
        return datetime.fromisoformat(dt_str)
    except Exception:
        return datetime.utcnow()


# Mock data containing both an Egypt match and an Al Ahly match
MOCK_MATCHES_RAW = [
    {
        "matchId": 2601,
        "teamId1": 122,
        "teamId2": 67,
        "matchStatus": 1,
        "stadiumName": "Cairo Int. Stadium",
        "stadiumNameAr": "استاد القاهرة الدولي",
        "teamName1": "Egypt",
        "teamNameAr1": "مصر",
        "teamName2": "South Africa",
        "teamNameAr2": "جنوب افريقيا",
        "team1Logo": "FE26082E-4EAE-4479-8DF0-920F0C59A19B.png",
        "team2Logo": "69E755EC-CCE7-4DCB-8D20-16C603BCC0B3.png",
        "date": "2026-10-04T00:00:00",
        "kickOffTime": "2026-10-04T21:00:00",
        "gatesOpenTime": "2026-10-04T16:00:00",
        "tournament": {
            "id": 122,
            "nameAr": "المباريات الودية الدولية.",
            "nameEn": "International Friendlies."
        },
        "showInPortal": True,
        "isDeleted": False,
        "maxTicketsPerUser": 4
    },
    {
        "matchId": 3105,
        "teamId1": 450,
        "teamId2": 890,
        "matchStatus": 1,
        "stadiumName": "Cairo Int. Stadium",
        "stadiumNameAr": "استاد القاهرة الدولي",
        "teamName1": "Al Ahly",
        "teamNameAr1": "الأهلي",
        "teamName2": "Mamelodi Sundowns",
        "teamNameAr2": "ماميلودي صنداونز",
        "team1Logo": "ahly_logo.png",
        "team2Logo": "sundowns_logo.png",
        "date": "2026-10-18T00:00:00",
        "kickOffTime": "2026-10-18T20:00:00",
        "gatesOpenTime": "2026-10-18T16:00:00",
        "tournament": {
            "id": 204,
            "nameAr": "دوري أبطال أفريقيا",
            "nameEn": "CAF Champions League"
        },
        "showInPortal": True,
        "isDeleted": False,
        "maxTicketsPerUser": 2
    }
]


def validate_response_shape(raw_data: Any) -> None:
    """
    Validates that the raw response is a list and each item contains required fields.
    Raises TazkartiValidationError on any structure irregularity.
    """
    if not isinstance(raw_data, list):
        raise TazkartiValidationError(f"Expected response to be list, got {type(raw_data).__name__}")

    for idx, item in enumerate(raw_data):
        if not isinstance(item, dict):
            raise TazkartiValidationError(f"Item #{idx} is not a JSON object: {type(item).__name__}")
        
        required_fields = ["matchId", "teamName1", "teamName2"]
        missing = [f for f in required_fields if f not in item or item[f] is None]
        if missing:
            raise TazkartiValidationError(
                f"Item #{idx} (matchId: {item.get('matchId')}) missing required fields: {missing}"
            )
        
        # Verify matchId is an integer
        if not isinstance(item["matchId"], int):
            try:
                int(item["matchId"])
            except (ValueError, TypeError):
                raise TazkartiValidationError(f"Item #{idx} matchId is not an integer: {item['matchId']}")


def parse_match(item: Dict[str, Any]) -> Match:
    """Parse a single raw Tazkarti match dictionary into a Match model."""
    tournament = item.get("tournament") or {}
    tournament_ar = tournament.get("nameAr", "") if isinstance(tournament, dict) else ""
    tournament_en = tournament.get("nameEn", "") if isinstance(tournament, dict) else ""

    return Match(
        match_id=int(item["matchId"]),
        team1_id=item.get("teamId1"),
        team2_id=item.get("teamId2"),
        team1_en=str(item.get("teamName1") or "").strip(),
        team1_ar=str(item.get("teamNameAr1") or "").strip(),
        team2_en=str(item.get("teamName2") or "").strip(),
        team2_ar=str(item.get("teamNameAr2") or "").strip(),
        kickoff=_parse_iso_datetime(item.get("kickOffTime")),
        tournament_ar=str(tournament_ar).strip(),
        tournament_en=str(tournament_en).strip(),
        stadium_ar=str(item.get("stadiumNameAr") or "").strip(),
        stadium_en=str(item.get("stadiumName") or "").strip(),
        match_status_raw=int(item.get("matchStatus", 0)),
        show_in_portal=bool(item.get("showInPortal", True)),
        is_deleted=bool(item.get("isDeleted", False)),
        url=TAZKARTI_BASE_URL,
        team1_logo=item.get("team1Logo"),
        team2_logo=item.get("team2Logo"),
        max_tickets_per_user=item.get("maxTicketsPerUser"),
        gates_open_time=item.get("gatesOpenTime"),
    )


def fetch_matches(client: Optional[httpx.Client] = None) -> List[Match]:
    """
    Fetches matches from Tazkarti public JSON endpoint.
    Uses fresh cache-buster timestamp query param.
    Validates structure strictly and returns list of Match objects.
    """
    if settings.mock_mode:
        logger.info("[MOCK] Returning simulated Tazkarti matches (Ahly + Egypt)")
        validate_response_shape(MOCK_MATCHES_RAW)
        return [parse_match(m) for m in MOCK_MATCHES_RAW]

    # Cache buster: current unix millisecond timestamp
    timestamp_ms = int(time.time() * 1000)
    url = f"{TAZKARTI_MATCHES_URL}?_={timestamp_ms}"

    owns_client = False
    if client is None:
        client = httpx.Client(timeout=settings.request_timeout_seconds)
        owns_client = True

    try:
        response = client.get(url, headers=DEFAULT_HEADERS)
        if response.status_code != 200:
            raise TazkartiFetchError(
                f"Tazkarti endpoint returned status {response.status_code}: {response.text[:200]}"
            )
        
        try:
            raw_json = response.json()
        except Exception as e:
            raise TazkartiValidationError(f"Invalid JSON returned from Tazkarti: {e}") from e

        validate_response_shape(raw_json)
        matches = [parse_match(item) for item in raw_json]
        logger.info(f"Successfully fetched and parsed {len(matches)} matches from Tazkarti")
        return matches

    except httpx.RequestError as exc:
        raise TazkartiFetchError(f"Network error requesting Tazkarti: {exc}") from exc
    finally:
        if owns_client:
            client.close()
