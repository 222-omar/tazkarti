import { TRACKED_TEAMS, TrackedTeam } from "./config";
import { Match } from "./tazkartiClient";

const ARABIC_DIACRITICS_REGEX =
  /[\u064B-\u065F\u0670\u06D6-\u06DC\u06DF-\u06E8\u06EA-\u06ED]/g;
const TATWEEL_REGEX = /\u0640/g;
const PUNCTUATION_REGEX = /[^\w\s\u0600-\u06FF]/gu;
const MULTIPLE_SPACES_REGEX = /\s+/g;

/**
 * Normalizes Arabic and English text for strict exact matching:
 * - Lowercase
 * - Remove tashkeel & tatweel
 * - Normalize Alef (أ, إ, آ, ٱ -> ا)
 * - Normalize Taa Marbouta (ة -> ه)
 * - Normalize Alef Maqsura (ى -> ي)
 * - Replace punctuation with space (e.g. "Al-Ahly" -> "al ahly")
 * - Trim and collapse whitespaces
 */
export function normalizeText(text?: string | null): string {
  if (!text) return "";

  let s = text.trim().normalize("NFKC").toLowerCase();

  // Strip tatweel
  s = s.replace(TATWEEL_REGEX, "");

  // Strip diacritics
  s = s.replace(ARABIC_DIACRITICS_REGEX, "");

  // Normalize Alef variations
  s = s.replace(/[أإآٱ]/g, "ا");

  // Normalize Taa Marbouta
  s = s.replace(/ة/g, "ه");

  // Normalize Alef Maqsura
  s = s.replace(/ى/g, "ي");

  // Punctuation to space
  s = s.replace(PUNCTUATION_REGEX, " ");

  // Collapse whitespaces
  s = s.replace(MULTIPLE_SPACES_REGEX, " ").trim();

  return s;
}

export interface MatchedTeamResult {
  key: string;
  topic: string;
  displayAr: string;
}

export class TeamMatcher {
  private normalizedTeams: Array<{
    key: string;
    topic: string;
    displayAr: string;
    teamIds: Set<number>;
    aliases: Set<string>;
  }>;

  constructor(trackedTeams: TrackedTeam[] = TRACKED_TEAMS) {
    this.normalizedTeams = trackedTeams.map((team) => {
      const aliases = new Set<string>();
      for (const a of team.aliases) {
        const norm = normalizeText(a);
        if (norm) aliases.add(norm);
      }
      if (team.displayAr) {
        const normDisplay = normalizeText(team.displayAr);
        if (normDisplay) aliases.add(normDisplay);
      }

      return {
        key: team.key,
        topic: team.topic,
        displayAr: team.displayAr,
        teamIds: new Set(team.teamIds),
        aliases,
      };
    });
  }

  /**
   * Evaluates if a given side (teamId + names) strictly matches a tracked team.
   * Uses ID if configured, otherwise exact normalized name match. NEVER substring.
   */
  private matchTeamSide(
    teamId: number | null | undefined,
    nameAr: string,
    nameEn: string,
    teamCfg: { teamIds: Set<number>; aliases: Set<string> }
  ): boolean {
    if (teamCfg.teamIds.size > 0 && teamId != null) {
      if (teamCfg.teamIds.has(teamId)) {
        return true;
      }
    }

    const normAr = normalizeText(nameAr);
    const normEn = normalizeText(nameEn);

    if (normAr && teamCfg.aliases.has(normAr)) {
      return true;
    }
    if (normEn && teamCfg.aliases.has(normEn)) {
      return true;
    }

    return false;
  }

  /**
   * Identifies all tracked teams that participate in this match.
   * Returns empty array if the match is deleted or hidden from the portal.
   */
  public identifyTeamsForMatch(match: Match): MatchedTeamResult[] {
    if (match.isDeleted || !match.showInPortal) {
      return [];
    }

    const matched: MatchedTeamResult[] = [];

    for (const teamCfg of this.normalizedTeams) {
      const team1Matches = this.matchTeamSide(
        match.team1Id,
        match.team1Ar,
        match.team1En,
        teamCfg
      );
      const team2Matches = this.matchTeamSide(
        match.team2Id,
        match.team2Ar,
        match.team2En,
        teamCfg
      );

      if (team1Matches || team2Matches) {
        matched.push({
          key: teamCfg.key,
          topic: teamCfg.topic,
          displayAr: teamCfg.displayAr,
        });
      }
    }

    return matched;
  }
}
