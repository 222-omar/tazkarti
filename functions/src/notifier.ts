import * as admin from "firebase-admin";
import { ANDROID_NOTIFICATION_CHANNEL_ID, ADMIN_ALERTS_TOPIC } from "./config";
import { Match } from "./tazkartiClient";

export type TransitionType = "NEW_MATCH" | "STATUS_CHANGED";

export function formatKickoffDate(isoDateStr: string): string {
  try {
    const dt = new Date(isoDateStr);
    if (isNaN(dt.getTime())) return isoDateStr;

    // Format in Arabic locale for Egypt time
    return new Intl.DateTimeFormat("ar-EG", {
      weekday: "long",
      year: "numeric",
      month: "short",
      day: "numeric",
      hour: "numeric",
      minute: "2-digit",
      hour12: true,
      timeZone: "Africa/Cairo",
    }).format(dt);
  } catch {
    return isoDateStr;
  }
}

export async function sendMatchNotification(params: {
  topic: string;
  teamKey: string;
  teamDisplayAr: string;
  match: Match;
  transitionType: TransitionType;
}): Promise<string> {
  const { topic, teamKey, teamDisplayAr, match, transitionType } = params;

  // Title formatting in Arabic
  const icon = teamKey === "ahly" ? "🔴" : teamKey === "egypt" ? "🇪🇬" : "⚽";
  let title = "";
  if (transitionType === "NEW_MATCH") {
    title = `${icon} مباراة جديدة لـ ${teamDisplayAr}`;
  } else {
    title = `${icon} تحديث في تذاكر ${teamDisplayAr}`;
  }

  const formattedTime = formatKickoffDate(match.kickoff);
  const body = `${match.team1Ar || match.team1En} vs ${match.team2Ar || match.team2En} - ${formattedTime}`;

  const message: admin.messaging.Message = {
    topic: topic,
    notification: {
      title,
      body,
    },
    data: {
      match_id: String(match.matchId),
      team_key: teamKey,
      team_display_ar: teamDisplayAr,
      match_status_raw: String(match.matchStatusRaw),
      kickoff: match.kickoff,
      url: match.url || "https://tazkarti.com/",
      click_action: "FLUTTER_NOTIFICATION_CLICK",
      type: transitionType,
    },
    android: {
      priority: "high",
      notification: {
        channelId: ANDROID_NOTIFICATION_CHANNEL_ID,
        priority: "max",
        visibility: "public", // Shows on lock screen outside the app
        defaultVibrateTimings: true,
        sound: "default",
        clickAction: "FLUTTER_NOTIFICATION_CLICK",
        notificationCount: 1,
      },
    },
    apns: {
      headers: {
        "apns-priority": "10",
      },
      payload: {
        aps: {
          alert: {
            title,
            body,
          },
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
    },
  };

  try {
    const response = await admin.messaging().send(message);
    console.log(
      `[Notifier] Successfully sent ${transitionType} notification for match ${match.matchId} to topic ${topic}. MessageId: ${response}`
    );
    return response;
  } catch (err: any) {
    console.error(`[Notifier] Failed to send notification to topic ${topic}:`, err);
    throw err;
  }
}

export async function sendAdminAlert(subject: string, details: string): Promise<void> {
  const message: admin.messaging.Message = {
    topic: ADMIN_ALERTS_TOPIC,
    notification: {
      title: `⚠️ تنبيه نظام تذكرتي: ${subject}`,
      body: details.slice(0, 200),
    },
    data: {
      type: "ADMIN_ALERT",
      subject,
      details: details.slice(0, 1000),
      timestamp: new Date().toISOString(),
    },
    android: {
      priority: "high",
      notification: {
        channelId: ANDROID_NOTIFICATION_CHANNEL_ID,
      },
    },
  };

  try {
    await admin.messaging().send(message);
    console.log(`[Notifier] Admin alert sent to ${ADMIN_ALERTS_TOPIC}`);
  } catch (err) {
    console.error("[Notifier] Failed to send admin alert:", err);
  }
}
