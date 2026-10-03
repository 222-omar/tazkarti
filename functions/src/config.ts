export interface TrackedTeam {
  key: string;
  topic: string;
  displayAr: string;
  teamIds: number[];
  aliases: string[];
}

export const TAZKARTI_BASE_URL = "https://tazkarti.com/";
export const TAZKARTI_MATCHES_URL = "https://tazkarti.com/data/matches-list-json.json";

export const DEFAULT_HEADERS = {
  "Accept": "application/json",
  "Referer": "https://tazkarti.com/",
  "User-Agent":
    "Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/125.0.0.0 Safari/537.36",
};

export const TRACKED_TEAMS: TrackedTeam[] = [
  {
    key: "ahly",
    topic: "ahly_tickets",
    displayAr: "الأهلي",
    teamIds: [], // TODO: Fill once an Ahly match is listed with verified teamId
    aliases: [
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
    key: "egypt",
    topic: "egypt_tickets",
    displayAr: "منتخب مصر",
    // teamId1=122 in the sample match Egypt vs South Africa, but equals tournament id 122, verify before trusting
    teamIds: [],
    aliases: [
      "مصر",
      "منتخب مصر",
      "Egypt",
      "Egypt National Team",
    ],
  },
];

export const ANDROID_NOTIFICATION_CHANNEL_ID = "tickets_high";
export const ADMIN_ALERTS_TOPIC = "admin_alerts";

export const CONFIG = {
  mockMode: process.env.MOCK === "1" || process.env.MOCK === "true",
  seedSilently: process.env.SEED_SILENTLY !== "false", // Default true
  requestTimeoutMs: 15000,
  failureAlertThreshold: parseInt(process.env.FAILURE_ALERT_THRESHOLD || "5", 10),
  matchesCollection: "matches",
  watcherStateCollection: "watcher_state",
};
