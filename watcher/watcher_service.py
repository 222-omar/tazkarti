import logging
from typing import Dict, Any, List, Optional
from .config import settings
from .tazkarti_client import fetch_matches, Match
from .matcher import TeamMatcher
from .firestore_repo import FirestoreRepository
from .notifier import send_match_notification, send_admin_alert

logger = logging.getLogger("tazkarti.watcher")


class WatcherService:
    def __init__(
        self,
        repo: Optional[FirestoreRepository] = None,
        matcher: Optional[TeamMatcher] = None,
    ):
        self.repo = repo or FirestoreRepository()
        self.matcher = matcher or TeamMatcher()

    def run_poll(self) -> Dict[str, Any]:
        """
        Executes one polling cycle:
        1. Fetches matches from Tazkarti.
        2. Assigns matches to tracked teams.
        3. Seeds silently if first run and SEED_SILENTLY=True.
        4. Detects transitions (new match, raw matchStatus change) and triggers FCM.
        5. Logs raw matchStatus transitions with matchId.
        6. Tracks health and alerts admin on repeated failures.
        """
        try:
            matches = fetch_matches()
            recovered = self.repo.record_health_success()
            if recovered:
                send_admin_alert(
                    "تم استعادة الاتصال بنجاح",
                    "نجح النظام في سحب بيانات تذكرتي والتحقق من بنيتها بشكل سليم بعد انقطاع."
                )
        except Exception as exc:
            logger.error(f"[Watcher] Fetch/Validation error: {exc}")
            should_alert = self.repo.record_health_failure(str(exc))
            if should_alert:
                send_admin_alert(
                    "فشل متكرر في الاتصال بـ Tazkarti",
                    f"فشل الاتصال أو التحقق من شكل البيانات بعد محاولات متتالية. الخطأ: {exc}"
                )
            raise

        notifications_sent = 0
        tracked_matches: List[Dict[str, Any]] = []

        for match in matches:
            matched_teams = self.matcher.identify_teams_for_match(match)
            if matched_teams:
                tracked_matches.append({
                    "match": match,
                    "matched_teams": matched_teams,
                })

        logger.info(
            f"[Watcher] Total matches: {len(matches)}, Tracked teams matches: {len(tracked_matches)}"
        )

        is_first_run = not self.repo.is_seeded()
        if is_first_run and settings.seed_silently:
            logger.info("[Watcher] First-run silent seeding active: writing matches without sending notifications.")
            for item in tracked_matches:
                m: Match = item["match"]
                team_keys = [t["key"] for t in item["matched_teams"]]
                self.repo.save_match(
                    match=m,
                    team_keys=team_keys,
                    notified_new=True,
                    last_notified_status=m.match_status_raw,
                )
            self.repo.mark_seeded(len(matches))
            return {
                "total_matches": len(matches),
                "tracked_matches": len(tracked_matches),
                "notifications_sent": 0,
                "seeded": True,
            }

        # Normal execution
        for item in tracked_matches:
            m: Match = item["match"]
            matched_teams = item["matched_teams"]
            team_keys = [t["key"] for t in matched_teams]

            existing_doc = self.repo.get_match(m.match_id)

            if existing_doc is None:
                # Transition (a): New match first seen
                logger.info(
                    f"[TRANSITION: NEW MATCH] matchId: {m.match_id} ({m.team1_ar} vs {m.team2_ar})"
                )
                for t in matched_teams:
                    try:
                        send_match_notification(
                            topic=t["topic"],
                            team_key=t["key"],
                            team_display_ar=t["display_ar"],
                            match=m,
                            transition_type="NEW_MATCH",
                        )
                        notifications_sent += 1
                    except Exception as err:
                        logger.error(f"Error sending new match FCM for {t['key']}: {err}")

                self.repo.save_match(
                    match=m,
                    team_keys=team_keys,
                    notified_new=True,
                    last_notified_status=m.match_status_raw,
                )
            else:
                # Transition (b): match_status_raw changed
                old_status = existing_doc.get("lastMatchStatusRaw")
                new_status = m.match_status_raw

                if old_status != new_status and existing_doc.get("lastNotifiedStatus") != new_status:
                    logger.info(
                        f"[TRANSITION: STATUS CHANGED] matchId: {m.match_id} raw matchStatus: {old_status} -> {new_status}"
                    )
                    for t in matched_teams:
                        try:
                            send_match_notification(
                                topic=t["topic"],
                                team_key=t["key"],
                                team_display_ar=t["display_ar"],
                                match=m,
                                transition_type="STATUS_CHANGED",
                            )
                            notifications_sent += 1
                        except Exception as err:
                            logger.error(f"Error sending status update FCM for {t['key']}: {err}")

                    self.repo.save_match(
                        match=m,
                        team_keys=team_keys,
                        notified_new=True,
                        last_notified_status=new_status,
                    )
                else:
                    self.repo.update_match_quietly(m, team_keys)

        return {
            "total_matches": len(matches),
            "tracked_matches": len(tracked_matches),
            "notifications_sent": notifications_sent,
            "seeded": False,
        }

    def force_test_notification(self, target_team_key: str = "egypt") -> str:
        """Forces an immediate test notification for the specified team."""
        matches = fetch_matches()
        target_match: Optional[Match] = None
        for m in matches:
            teams = self.matcher.identify_teams_for_match(m)
            if any(t["key"] == target_team_key for t in teams):
                target_match = m
                break

        if not target_match:
            # Fallback to sample Egypt match
            from datetime import datetime
            target_match = Match(
                match_id=2601,
                team1_id=122,
                team2_id=67,
                team1_ar="مصر" if target_team_key == "egypt" else "الأهلي",
                team1_en="Egypt" if target_team_key == "egypt" else "Al Ahly",
                team2_ar="جنوب افريقيا",
                team2_en="South Africa",
                kickoff=datetime(2026, 10, 4, 21, 0, 0),
                tournament_ar="المباريات الودية الدولية.",
                tournament_en="International Friendlies.",
                stadium_ar="استاد القاهرة الدولي",
                match_status_raw=1,
                show_in_portal=True,
                is_deleted=False,
            )

        topic = "egypt_tickets" if target_team_key == "egypt" else "ahly_tickets"
        display_ar = "منتخب مصر" if target_team_key == "egypt" else "الأهلي"

        msg_id = send_match_notification(
            topic=topic,
            team_key=target_team_key,
            team_display_ar=display_ar,
            match=target_match,
            transition_type="NEW_MATCH",
        )
        return str(msg_id)
