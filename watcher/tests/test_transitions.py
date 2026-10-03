from unittest.mock import MagicMock, patch
from datetime import datetime
from watcher.watcher_service import WatcherService
from watcher.tazkarti_client import Match
from watcher.config import settings


def _make_match(match_id=2601, status=1):
    return Match(
        match_id=match_id,
        team1_id=122,
        team2_id=67,
        team1_ar="مصر",
        team1_en="Egypt",
        team2_ar="جنوب افريقيا",
        team2_en="South Africa",
        kickoff=datetime(2026, 10, 4, 21, 0),
        tournament_ar="المباريات الودية الدولية.",
        tournament_en="International Friendlies.",
        stadium_ar="استاد القاهرة الدولي",
        match_status_raw=status,
        show_in_portal=True,
        is_deleted=False,
    )


def test_first_run_silent_seeding(monkeypatch):
    monkeypatch.setattr(settings, "seed_silently", True)

    mock_repo = MagicMock()
    mock_repo.is_seeded.return_value = False  # First run
    mock_repo.record_health_success.return_value = False

    with patch("watcher.watcher_service.fetch_matches", return_value=[_make_match()]), \
         patch("watcher.watcher_service.send_match_notification") as mock_notify:

        service = WatcherService(repo=mock_repo)
        result = service.run_poll()

        assert result["seeded"] is True
        assert result["notifications_sent"] == 0
        mock_notify.assert_not_called()
        mock_repo.save_match.assert_called_once()
        mock_repo.mark_seeded.assert_called_once()


def test_new_match_transition(monkeypatch):
    monkeypatch.setattr(settings, "seed_silently", True)

    mock_repo = MagicMock()
    mock_repo.is_seeded.return_value = True  # Already seeded
    mock_repo.get_match.return_value = None  # Match not stored yet -> NEW!
    mock_repo.record_health_success.return_value = False

    match = _make_match(match_id=5000, status=1)

    with patch("watcher.watcher_service.fetch_matches", return_value=[match]), \
         patch("watcher.watcher_service.send_match_notification") as mock_notify:

        service = WatcherService(repo=mock_repo)
        result = service.run_poll()

        assert result["notifications_sent"] == 1
        mock_notify.assert_called_once()
        call_kwargs = mock_notify.call_args[1]
        assert call_kwargs["transition_type"] == "NEW_MATCH"
        assert call_kwargs["topic"] == "egypt_tickets"
        mock_repo.save_match.assert_called_once()


def test_status_change_transition(monkeypatch):
    mock_repo = MagicMock()
    mock_repo.is_seeded.return_value = True
    # Existing match has raw status 1
    mock_repo.get_match.return_value = {
        "matchId": 2601,
        "lastMatchStatusRaw": 1,
        "lastNotifiedStatus": 1,
    }
    mock_repo.record_health_success.return_value = False

    # Incoming match now has status 2
    match = _make_match(match_id=2601, status=2)

    with patch("watcher.watcher_service.fetch_matches", return_value=[match]), \
         patch("watcher.watcher_service.send_match_notification") as mock_notify:

        service = WatcherService(repo=mock_repo)
        result = service.run_poll()

        assert result["notifications_sent"] == 1
        mock_notify.assert_called_once()
        call_kwargs = mock_notify.call_args[1]
        assert call_kwargs["transition_type"] == "STATUS_CHANGED"
        mock_repo.save_match.assert_called_once()


def test_idempotent_no_duplicate_notifications():
    mock_repo = MagicMock()
    mock_repo.is_seeded.return_value = True
    # Existing match already has raw status 1 and already notified
    mock_repo.get_match.return_value = {
        "matchId": 2601,
        "lastMatchStatusRaw": 1,
        "lastNotifiedStatus": 1,
    }
    mock_repo.record_health_success.return_value = False

    # Incoming match still has status 1
    match = _make_match(match_id=2601, status=1)

    with patch("watcher.watcher_service.fetch_matches", return_value=[match]), \
         patch("watcher.watcher_service.send_match_notification") as mock_notify:

        service = WatcherService(repo=mock_repo)
        result = service.run_poll()

        assert result["notifications_sent"] == 0
        mock_notify.assert_not_called()
        mock_repo.update_match_quietly.assert_called_once()
