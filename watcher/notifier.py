import logging
from datetime import datetime
from typing import Dict, Any, Optional
import firebase_admin
from firebase_admin import messaging

from .config import ANDROID_NOTIFICATION_CHANNEL_ID, ADMIN_ALERTS_TOPIC
from .tazkarti_client import Match
from .firestore_repo import init_firebase

logger = logging.getLogger("tazkarti.notifier")


def format_arabic_kickoff(dt: datetime) -> str:
    """Format kickoff date/time cleanly in Arabic format."""
    months_ar = [
        "يناير", "فبراير", "مارس", "أبريل", "مايو", "يونيو",
        "يوليو", "أغسطس", "سبتمبر", "أكتوبر", "نوفمبر", "ديسمبر"
    ]
    days_ar = [
        "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت", "الأحد"
    ]
    day_name = days_ar[dt.weekday()]
    month_name = months_ar[dt.month - 1]
    
    hour = dt.hour
    am_pm = "م" if hour >= 12 else "ص"
    hour_12 = hour % 12
    if hour_12 == 0:
        hour_12 = 12
    time_str = f"{hour_12:02d}:{dt.minute:02d} {am_pm}"

    return f"{day_name} {dt.day} {month_name} {dt.year} - {time_str}"


def send_match_notification(
    topic: str,
    team_key: str,
    team_display_ar: str,
    match: Match,
    transition_type: str,  # "NEW_MATCH" or "STATUS_CHANGED"
) -> Optional[str]:
    """
    Sends an FCM topic push notification with MAXIMUM priority for Android & iOS.
    Configured so it displays prominently on lock-screen and heads-up popups outside the app.
    """
    icon = "🔴" if team_key == "ahly" else "🇪🇬" if team_key == "egypt" else "⚽"
    
    if transition_type == "NEW_MATCH":
        title = f"{icon} مباراة جديدة لـ {team_display_ar}"
    else:
        title = f"{icon} تحديث في تذاكر {team_display_ar}"

    formatted_time = format_arabic_kickoff(match.kickoff)
    body = f"{match.team1_ar or match.team1_en} vs {match.team2_ar or match.team2_en} - {formatted_time}"

    data_payload: Dict[str, str] = {
        "match_id": str(match.match_id),
        "team_key": team_key,
        "team_display_ar": team_display_ar,
        "match_status_raw": str(match.match_status_raw),
        "kickoff": match.kickoff.isoformat(),
        "url": match.url,
        "click_action": "FLUTTER_NOTIFICATION_CLICK",
        "type": transition_type,
    }

    message = messaging.Message(
        topic=topic,
        notification=messaging.Notification(
            title=title,
            body=body,
        ),
        data=data_payload,
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id=ANDROID_NOTIFICATION_CHANNEL_ID,
                priority="max",
                visibility="public",  # Shows on lock screen
                default_vibrate_timings=True,
                sound="default",
                click_action="FLUTTER_NOTIFICATION_CLICK",
            ),
        ),
        apns=messaging.APNSConfig(
            headers={"apns-priority": "10"},
            payload=messaging.APNSPayload(
                aps=messaging.Aps(
                    alert=messaging.ApsAlert(title=title, body=body),
                    sound="default",
                    badge=1,
                    content_available=True,
                )
            ),
        ),
    )

    try:
        init_firebase()
        response = messaging.send(message)
        logger.info(
            f"[Notifier] Sent {transition_type} to topic '{topic}' for match {match.match_id}. MessageId: {response}"
        )
        return response
    except Exception as exc:
        logger.error(f"[Notifier] Failed to send notification to topic '{topic}': {exc}")
        raise


def send_admin_alert(subject: str, details: str) -> None:
    """Send alert to admin_alerts topic when repeated errors occur."""
    message = messaging.Message(
        topic=ADMIN_ALERTS_TOPIC,
        notification=messaging.Notification(
            title=f"⚠️ تنبيه نظام تذكرتي: {subject}",
            body=details[:200],
        ),
        data={
            "type": "ADMIN_ALERT",
            "subject": subject,
            "details": details[:1000],
            "timestamp": datetime.utcnow().isoformat(),
        },
        android=messaging.AndroidConfig(
            priority="high",
            notification=messaging.AndroidNotification(
                channel_id=ANDROID_NOTIFICATION_CHANNEL_ID,
            ),
        ),
    )
    try:
        messaging.send(message)
        logger.info(f"[Notifier] Admin alert sent to {ADMIN_ALERTS_TOPIC}")
    except Exception as exc:
        logger.error(f"[Notifier] Failed to send admin alert: {exc}")
