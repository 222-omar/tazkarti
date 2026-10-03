import re
import unicodedata
from typing import List, Dict, Any, Set
from .config import TRACKED_TEAMS
from .tazkarti_client import Match

# Arabic tashkeel (diacritics)
ARABIC_DIACRITICS_REGEX = re.compile(
    r"[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]"
)

# Tatweel (kashida)
TATWEEL = "\u0640"

# Non-alphanumeric punctuation to replace with space
PUNCTUATION_REGEX = re.compile(r"[^\w\s\u0600-\u06FF]", re.UNICODE)
MULTIPLE_SPACES_REGEX = re.compile(r"\s+")


def normalize_text(text: str) -> str:
    """
    Normalizes Arabic and English team names for strict exact-matching:
    - Lowercase
    - Remove Arabic diacritics (tashkeel) and tatweel (kashida)
    - Normalize Arabic letters:
        أ, إ, آ, ٱ -> ا
        ة -> ه
        ى -> ي
    - Strip punctuation and symbols (converting hyphens/dots to spaces)
    - Collapse multiple spaces into single space and strip borders.
    """
    if not text:
        return ""

    # Normalize unicode to NFKC
    s = unicodedata.normalize("NFKC", text.strip())

    # Lowercase
    s = s.lower()

    # Remove tatweel
    s = s.replace(TATWEEL, "")

    # Remove Arabic diacritics
    s = ARABIC_DIACRITICS_REGEX.sub("", s)

    # Normalize Alef variations
    for alef in ("أ", "إ", "آ", "ٱ"):
        s = s.replace(alef, "ا")

    # Normalize Taa Marbouta to Haa
    s = s.replace("ة", "ه")

    # Normalize Alef Maqsura to Yaa
    s = s.replace("ى", "ي")

    # Replace punctuation with space so "al-ahly" becomes "al ahly"
    s = PUNCTUATION_REGEX.sub(" ", s)

    # Collapse multiple whitespaces
    s = MULTIPLE_SPACES_REGEX.sub(" ", s).strip()

    return s


class TeamMatcher:
    def __init__(self, tracked_teams: List[Dict[str, Any]] = TRACKED_TEAMS):
        self.tracked_teams = tracked_teams
        # Pre-normalize aliases for fast & reliable exact comparison
        self._normalized_team_configs = []
        for team in self.tracked_teams:
            norm_aliases = {normalize_text(a) for a in team.get("aliases", [])}
            # Also add normalized display_ar if present
            if team.get("display_ar"):
                norm_aliases.add(normalize_text(team["display_ar"]))
            self._normalized_team_configs.append({
                "key": team["key"],
                "topic": team["topic"],
                "display_ar": team["display_ar"],
                "team_ids": set(team.get("team_ids", [])),
                "aliases": norm_aliases,
            })

    def match_team(
        self,
        team_id: int | None,
        team_name_ar: str,
        team_name_en: str,
        team_cfg: Dict[str, Any],
    ) -> bool:
        """
        Check if a given team side matches a tracked team config.
        Rules:
        - Match by team_id when configured and non-empty.
        - Otherwise, match by EXACT EQUALITY after normalization (NEVER substring).
        """
        # Match by ID if team_ids are configured for this team
        if team_cfg["team_ids"] and team_id is not None:
            if team_id in team_cfg["team_ids"]:
                return True

        # Exact match on normalized names
        norm_ar = normalize_text(team_name_ar)
        norm_en = normalize_text(team_name_en)

        aliases: Set[str] = team_cfg["aliases"]

        if norm_ar and norm_ar in aliases:
            return True
        if norm_en and norm_en in aliases:
            return True

        return False

    def identify_teams_for_match(self, match: Match) -> List[Dict[str, Any]]:
        """
        Returns list of tracked team configs that this match belongs to.
        A match belongs to a team if team1 OR team2 matches.
        Skips matches that are deleted (is_deleted=True) or hidden (show_in_portal=False).
        """
        if match.is_deleted or not match.show_in_portal:
            return []

        matched_teams = []
        for team_cfg in self._normalized_team_configs:
            # Check team 1 (home)
            team1_matches = self.match_team(
                match.team1_id, match.team1_ar, match.team1_en, team_cfg
            )
            # Check team 2 (away)
            team2_matches = self.match_team(
                match.team2_id, match.team2_ar, match.team2_en, team_cfg
            )

            if team1_matches or team2_matches:
                matched_teams.append({
                    "key": team_cfg["key"],
                    "topic": team_cfg["topic"],
                    "display_ar": team_cfg["display_ar"],
                })

        return matched_teams
