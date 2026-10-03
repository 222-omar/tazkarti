import axios from "axios";
import { TAZKARTI_MATCHES_URL, TAZKARTI_BASE_URL, DEFAULT_HEADERS, CONFIG } from "./config";

export interface Match {
  matchId: number;
  team1Id?: number | null;
  team2Id?: number | null;
  team1En: string;
  team1Ar: string;
  team2En: string;
  team2Ar: string;
  kickoff: string; // ISO format string
  tournamentAr: string;
  tournamentEn: string;
  stadiumAr: string;
  stadiumEn: string;
  matchStatusRaw: number;
  showInPortal: boolean;
  isDeleted: boolean;
  url: string;
  team1Logo?: string | null;
  team2Logo?: string | null;
  maxTicketsPerUser?: number | null;
  gatesOpenTime?: string | null;
}

export class TazkartiValidationError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TazkartiValidationError";
  }
}

export class TazkartiFetchError extends Error {
  constructor(message: string) {
    super(message);
    this.name = "TazkartiFetchError";
  }
}

export const MOCK_MATCHES_RAW: any[] = [
  {
    matchId: 2601,
    teamId1: 122,
    teamId2: 67,
    matchStatus: 1,
    stadiumName: "Cairo Int. Stadium",
    stadiumNameAr: "استاد القاهرة الدولي",
    teamName1: "Egypt",
    teamNameAr1: "مصر",
    teamName2: "South Africa",
    teamNameAr2: "جنوب افريقيا",
    team1Logo: "FE26082E-4EAE-4479-8DF0-920F0C59A19B.png",
    team2Logo: "69E755EC-CCE7-4DCB-8D20-16C603BCC0B3.png",
    date: "2026-10-04T00:00:00",
    kickOffTime: "2026-10-04T21:00:00",
    gatesOpenTime: "2026-10-04T16:00:00",
    tournament: {
      id: 122,
      nameAr: "المباريات الودية الدولية.",
      nameEn: "International Friendlies.",
    },
    showInPortal: true,
    isDeleted: false,
    maxTicketsPerUser: 4,
  },
  {
    matchId: 3105,
    teamId1: 450,
    teamId2: 890,
    matchStatus: 1,
    stadiumName: "Cairo Int. Stadium",
    stadiumNameAr: "استاد القاهرة الدولي",
    teamName1: "Al Ahly",
    teamNameAr1: "الأهلي",
    teamName2: "Mamelodi Sundowns",
    teamNameAr2: "ماميلودي صنداونز",
    team1Logo: "ahly_logo.png",
    team2Logo: "sundowns_logo.png",
    date: "2026-10-18T00:00:00",
    kickOffTime: "2026-10-18T20:00:00",
    gatesOpenTime: "2026-10-18T16:00:00",
    tournament: {
      id: 204,
      nameAr: "دوري أبطال أفريقيا",
      nameEn: "CAF Champions League",
    },
    showInPortal: true,
    isDeleted: false,
    maxTicketsPerUser: 2,
  },
];

export function validateResponseShape(rawData: unknown): void {
  if (!Array.isArray(rawData)) {
    throw new TazkartiValidationError(
      `Expected response to be array, got ${typeof rawData}`
    );
  }

  for (let i = 0; i < rawData.length; i++) {
    const item = rawData[i];
    if (!item || typeof item !== "object") {
      throw new TazkartiValidationError(`Item #${i} is not a valid object`);
    }

    if (item.matchId === undefined || item.matchId === null) {
      throw new TazkartiValidationError(`Item #${i} missing matchId`);
    }

    if (typeof item.matchId !== "number" && isNaN(Number(item.matchId))) {
      throw new TazkartiValidationError(
        `Item #${i} matchId is not a valid number: ${item.matchId}`
      );
    }

    if (!item.teamName1) {
      throw new TazkartiValidationError(
        `Item #${i} (matchId: ${item.matchId}) missing teamName1`
      );
    }

    if (!item.teamName2) {
      throw new TazkartiValidationError(
        `Item #${i} (matchId: ${item.matchId}) missing teamName2`
      );
    }
  }
}

export function parseMatch(item: any): Match {
  const tournament = item.tournament || {};
  return {
    matchId: Number(item.matchId),
    team1Id: item.teamId1 != null ? Number(item.teamId1) : null,
    team2Id: item.teamId2 != null ? Number(item.teamId2) : null,
    team1En: String(item.teamName1 || "").trim(),
    team1Ar: String(item.teamNameAr1 || "").trim(),
    team2En: String(item.teamName2 || "").trim(),
    team2Ar: String(item.teamNameAr2 || "").trim(),
    kickoff: String(item.kickOffTime || new Date().toISOString()).trim(),
    tournamentAr: String(tournament.nameAr || "").trim(),
    tournamentEn: String(tournament.nameEn || "").trim(),
    stadiumAr: String(item.stadiumNameAr || "").trim(),
    stadiumEn: String(item.stadiumName || "").trim(),
    matchStatusRaw: Number(item.matchStatus ?? 0),
    showInPortal: item.showInPortal !== false,
    isDeleted: Boolean(item.isDeleted),
    url: TAZKARTI_BASE_URL,
    team1Logo: item.team1Logo || null,
    team2Logo: item.team2Logo || null,
    maxTicketsPerUser: item.maxTicketsPerUser ? Number(item.maxTicketsPerUser) : null,
    gatesOpenTime: item.gatesOpenTime || null,
  };
}

export async function fetchMatches(): Promise<Match[]> {
  if (CONFIG.mockMode) {
    validateResponseShape(MOCK_MATCHES_RAW);
    return MOCK_MATCHES_RAW.map(parseMatch);
  }

  const timestampMs = Date.now();
  const url = `${TAZKARTI_MATCHES_URL}?_=${timestampMs}`;

  try {
    const response = await axios.get(url, {
      headers: DEFAULT_HEADERS,
      timeout: CONFIG.requestTimeoutMs,
      validateStatus: (status) => status === 200,
    });

    const rawData = response.data;
    validateResponseShape(rawData);

    return rawData.map(parseMatch);
  } catch (err: any) {
    if (err instanceof TazkartiValidationError) {
      throw err;
    }
    const message = err.response
      ? `HTTP ${err.response.status}: ${JSON.stringify(err.response.data).slice(0, 200)}`
      : err.message;
    throw new TazkartiFetchError(`Failed to fetch matches from Tazkarti: ${message}`);
  }
}
