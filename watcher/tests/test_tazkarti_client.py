import pytest
from watcher.tazkarti_client import (
    validate_response_shape,
    parse_match,
    fetch_matches,
    TazkartiValidationError,
    MOCK_MATCHES_RAW,
)
from watcher.config import settings


def test_validate_response_shape_valid():
    sample = [
        {"matchId": 10, "teamName1": "Team A", "teamName2": "Team B"},
        {"matchId": 20, "teamName1": "Team C", "teamName2": "Team D"},
    ]
    # Should not raise
    validate_response_shape(sample)


def test_validate_response_shape_invalid_types():
    with pytest.raises(TazkartiValidationError, match="Expected response to be list"):
        validate_response_shape({"error": "not a list"})

    with pytest.raises(TazkartiValidationError, match="not a JSON object"):
        validate_response_shape(["not an object"])


def test_validate_response_shape_missing_fields():
    with pytest.raises(TazkartiValidationError, match="missing required fields"):
        validate_response_shape([{"matchId": 10, "teamName1": "Egypt"}])  # missing teamName2

    with pytest.raises(TazkartiValidationError, match="missing required fields"):
        validate_response_shape([{"teamName1": "Egypt", "teamName2": "Ghana"}])  # missing matchId


def test_parse_match_model():
    item = MOCK_MATCHES_RAW[0]
    match = parse_match(item)
    assert match.match_id == 2601
    assert match.team1_ar == "مصر"
    assert match.team2_ar == "جنوب افريقيا"
    assert match.match_status_raw == 1
    assert match.show_in_portal is True
    assert match.is_deleted is False


def test_fetch_matches_mock_mode(monkeypatch):
    monkeypatch.setattr(settings, "mock_mode", True)
    matches = fetch_matches()
    assert len(matches) == 2
    # Verify contains both Egypt and Ahly
    team_names = [m.team1_ar for m in matches]
    assert "مصر" in team_names
    assert "الأهلي" in team_names
