import * as admin from "firebase-admin";
import { onSchedule } from "firebase-functions/v2/scheduler";
import { onRequest } from "firebase-functions/v2/https";
import { WatcherService } from "./watcherService";

// Initialize Firebase Admin SDK
admin.initializeApp();

const watcherService = new WatcherService();

/**
 * Scheduled Cloud Function: Runs automatically every 1 minute.
 * Checks Tazkarti, updates Firestore, and fires FCM push notifications on transitions.
 */
export const tazkartiWatcher = onSchedule(
  {
    schedule: "every 1 minutes",
    timeZone: "Africa/Cairo",
    retryCount: 1,
    timeoutSeconds: 60,
    memory: "256MiB",
  },
  async () => {
    console.log("[Tazkarti Scheduled Watcher] Starting poll execution...");
    const result = await watcherService.runPoll();
    console.log("[Tazkarti Scheduled Watcher] Finished execution:", result);
  }
);

/**
 * On-demand HTTP Endpoint to run a poll manually (e.g. from Cloud Scheduler or external healthcheck)
 * URL: https://<region>-<project-id>.cloudfunctions.net/pollMatches
 */
export const pollMatches = onRequest(
  { cors: true, timeoutSeconds: 60 },
  async (req, res) => {
    try {
      const result = await watcherService.runPoll();
      res.status(200).json({ status: "success", result });
    } catch (err: any) {
      console.error("[pollMatches HTTP] Error:", err);
      res.status(500).json({ status: "error", message: err.message || String(err) });
    }
  }
);

/**
 * On-demand HTTP Endpoint to send an immediate test push notification for Egypt or Al Ahly.
 * Allows the user to verify phone lock-screen / heads-up notification right away!
 * Query/Body param: team=egypt or team=ahly
 * URL: https://<region>-<project-id>.cloudfunctions.net/sendTestNotification?team=egypt
 */
export const sendTestNotification = onRequest(
  { cors: true, timeoutSeconds: 30 },
  async (req, res) => {
    try {
      const team = (req.query.team || req.body?.team || "egypt") as string;
      const result = await watcherService.triggerTestNotification(team);
      res.status(200).json({
        status: "success",
        message: `تم إرسال إشعار تجريبي بنجاح إلى توبيك ${team}_tickets!`,
        result,
      });
    } catch (err: any) {
      console.error("[sendTestNotification HTTP] Error:", err);
      res.status(500).json({ status: "error", message: err.message || String(err) });
    }
  }
);
