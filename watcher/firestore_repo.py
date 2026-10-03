import os
import logging
from datetime import datetime
from typing import Dict, Any, Optional, List
import firebase_admin
from firebase_admin import credentials, firestore
from .config import settings
from .tazkarti_client import Match

logger = logging.getLogger("tazkarti.firestore")


def init_firebase():
    if not firebase_admin._apps:
        # 1. Check if raw JSON string is passed via env var (e.g. on Render / Cloud)
        raw_json_env = os.getenv("FIREBASE_SERVICE_ACCOUNT")
        if raw_json_env and raw_json_env.strip().startswith("{"):
            import json
            try:
                cert_dict = json.loads(raw_json_env)
                logger.info("Initializing Firebase using FIREBASE_SERVICE_ACCOUNT env variable")
                cred = credentials.Certificate(cert_dict)
                firebase_admin.initialize_app(cred)
                return
            except Exception as e:
                logger.error(f"Failed to parse FIREBASE_SERVICE_ACCOUNT JSON: {e}")

        # 2. Check for file path
        import glob
        cred_path = os.getenv("GOOGLE_APPLICATION_CREDENTIALS")
        if not cred_path or not os.path.exists(cred_path):
            candidates = [
                "serviceAccountKey.json",
                "watcher/serviceAccountKey.json",
                "../serviceAccountKey.json",
            ]
            candidates.extend(glob.glob("*firebase-adminsdk*.json"))
            candidates.extend(glob.glob("../*firebase-adminsdk*.json"))
            candidates.extend(glob.glob("watcher/*firebase-adminsdk*.json"))
            candidates.extend(glob.glob(os.path.join(os.path.dirname(__file__), "..", "*firebase-adminsdk*.json")))
            candidates.extend(glob.glob(os.path.join(os.path.dirname(__file__), "*firebase-adminsdk*.json")))

            for candidate in candidates:
                if os.path.exists(candidate):
                    cred_path = candidate
                    break

        if cred_path and os.path.exists(cred_path):
            logger.info(f"Initializing Firebase with service account key: {cred_path}")
            cred = credentials.Certificate(cred_path)
            firebase_admin.initialize_app(cred)
        else:
            firebase_admin.initialize_app()


class FirestoreRepository:
    def __init__(self):
        self._db: Optional[firestore.Client] = None

    @property
    def db(self) -> firestore.Client:
        if self._db is None:
            init_firebase()
            self._db = firestore.client()
        return self._db

    def get_match(self, match_id: int) -> Optional[Dict[str, Any]]:
        doc = self.db.collection(settings.firestore_collection).document(str(match_id)).get()
        return doc.to_dict() if doc.exists else None

    def save_match(
        self,
        match: Match,
        team_keys: List[str],
        notified_new: bool,
        last_notified_status: int,
    ) -> None:
        ref = self.db.collection(settings.firestore_collection).document(str(match.match_id))
        now = datetime.utcnow().isoformat()
        
        data = {
            "matchId": match.match_id,
            "teamKeys": team_keys,
            "lastMatchStatusRaw": match.match_status_raw,
            "firstSeenAt": now,
            "updatedAt": now,
            "notifiedNew": notified_new,
            "lastNotifiedStatus": last_notified_status,
            "team1Id": match.team1_id,
            "team2Id": match.team2_id,
            "team1Ar": match.team1_ar,
            "team1En": match.team1_en,
            "team2Ar": match.team2_ar,
            "team2En": match.team2_en,
            "kickoff": match.kickoff.isoformat(),
            "tournamentAr": match.tournament_ar,
            "tournamentEn": match.tournament_en,
            "stadiumAr": match.stadium_ar,
            "stadiumEn": match.stadium_en,
            "showInPortal": match.show_in_portal,
            "isDeleted": match.is_deleted,
            "url": match.url,
            "team1Logo": match.team1_logo,
            "team2Logo": match.team2_logo,
            "maxTicketsPerUser": match.max_tickets_per_user,
            "gatesOpenTime": match.gates_open_time,
        }
        ref.set(data, merge=True)

    def update_match_quietly(self, match: Match, team_keys: List[str]) -> None:
        ref = self.db.collection(settings.firestore_collection).document(str(match.match_id))
        ref.set({
            "lastMatchStatusRaw": match.match_status_raw,
            "teamKeys": team_keys,
            "updatedAt": datetime.utcnow().isoformat(),
            "showInPortal": match.show_in_portal,
            "isDeleted": match.is_deleted,
            "stadiumAr": match.stadium_ar,
            "tournamentAr": match.tournament_ar,
            "kickoff": match.kickoff.isoformat(),
        }, merge=True)

    def is_seeded(self) -> bool:
        doc = self.db.collection(settings.watcher_state_collection).document("global").get()
        return bool(doc.exists and doc.to_dict().get("isSeeded"))

    def mark_seeded(self, match_count: int) -> None:
        self.db.collection(settings.watcher_state_collection).document("global").set({
            "isSeeded": True,
            "seededAt": firestore.SERVER_TIMESTAMP,
            "initialMatchCount": match_count,
        }, merge=True)

    def record_health_success(self) -> bool:
        """Returns True if it previously alerted and now recovered."""
        ref = self.db.collection(settings.watcher_state_collection).document("health")
        doc = ref.get()
        recovered = False
        if doc.exists:
            data = doc.to_dict()
            if data.get("hasAlerted"):
                recovered = True

        ref.set({
            "consecutiveFailures": 0,
            "hasAlerted": False,
            "lastSuccessAt": firestore.SERVER_TIMESTAMP,
            "lastError": None,
        })
        return recovered

    def record_health_failure(self, error_message: str) -> bool:
        """Returns True if the failure alert threshold was newly breached."""
        ref = self.db.collection(settings.watcher_state_collection).document("health")
        doc = ref.get()
        current = doc.to_dict().get("consecutiveFailures", 0) if doc.exists else 0
        has_alerted = doc.to_dict().get("hasAlerted", False) if doc.exists else False
        new_count = current + 1

        should_alert = (new_count >= settings.failure_alert_threshold) and not has_alerted

        ref.set({
            "consecutiveFailures": new_count,
            "hasAlerted": has_alerted or should_alert,
            "lastFailureAt": firestore.SERVER_TIMESTAMP,
            "lastError": error_message,
        }, merge=True)

        return should_alert
