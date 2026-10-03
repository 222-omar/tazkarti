import { normalizeText, TeamMatcher } from "./matcher";
import { Match } from "./tazkartiClient";
import assert from "node:assert";
import { describe, it } from "node:test";

describe("Arabic Normalization & Exact Matching Tests", () => {
  it("normalizes Arabic Alef variations (أ, إ, آ, ٱ -> ا)", () => {
    assert.strictEqual(normalizeText("الأهلي"), "الاهلي");
    assert.strictEqual(normalizeText("إفريقيا"), "افريقيا");
    assert.strictEqual(normalizeText("آسيا"), "اسيا");
  });

  it("normalizes Taa Marbouta (ة -> ه) and Alef Maqsura (ى -> ي)", () => {
    assert.strictEqual(normalizeText("المقاصة"), "المقاصه");
    assert.strictEqual(normalizeText("الأهلى"), "الاهلي");
  });

  it("removes Arabic diacritics (tashkeel) and tatweel", () => {
    assert.strictEqual(normalizeText("مِصْرُ"), "مصر");
    assert.strictEqual(normalizeText("الأهْـلِـي"), "الاهلي");
  });

  it("normalizes punctuation and collapses whitespace", () => {
    assert.strictEqual(normalizeText("Al-Ahly   FC"), "al ahly fc");
    assert.strictEqual(normalizeText("  Egypt !  "), "egypt");
  });

  it("EXACT MATCH: never matches substring or unrelated teams", () => {
    const matcher = new TeamMatcher();

    // Helper match factory
    const createMockMatch = (team1Ar: string, team1En: string): Match => ({
      matchId: 999,
      team1Id: 10,
      team2Id: 20,
      team1Ar,
      team1En,
      team2Ar: "منافس",
      team2En: "Opponent",
      kickoff: "2026-10-04T21:00:00",
      tournamentAr: "بطولة",
      tournamentEn: "Tournament",
      stadiumAr: "استاد",
      stadiumEn: "Stadium",
      matchStatusRaw: 1,
      showInPortal: true,
      isDeleted: false,
      url: "https://tazkarti.com/",
    });

    // Valid Egypt matches
    const egyptMatch = createMockMatch("مصر", "Egypt");
    const egyptTeams = matcher.identifyTeamsForMatch(egyptMatch);
    assert.strictEqual(egyptTeams.length, 1);
    assert.strictEqual(egyptTeams[0].key, "egypt");

    // "المصري" should NEVER match "مصر"
    const masryMatch = createMockMatch("المصري", "Al Masry");
    const masryTeams = matcher.identifyTeamsForMatch(masryMatch);
    assert.strictEqual(masryTeams.length, 0, "المصري must not match مصر");

    // "مصر المقاصة" should NEVER match "مصر"
    const makassaMatch = createMockMatch("مصر المقاصة", "Misr Lel Makkasa");
    const makassaTeams = matcher.identifyTeamsForMatch(makassaMatch);
    assert.strictEqual(makassaTeams.length, 0, "مصر المقاصة must not match مصر");

    // Valid Ahly match
    const ahlyMatch = createMockMatch("النادي الأهلي", "Al Ahly");
    const ahlyTeams = matcher.identifyTeamsForMatch(ahlyMatch);
    assert.strictEqual(ahlyTeams.length, 1);
    assert.strictEqual(ahlyTeams[0].key, "ahly");

    // "أهلي طرابلس" or other Ahli should NOT match
    const ahliTripoli = createMockMatch("أهلي طرابلس", "Ahli Tripoli");
    const tripoliTeams = matcher.identifyTeamsForMatch(ahliTripoli);
    assert.strictEqual(tripoliTeams.length, 0);
  });

  it("handles Home and Away matching", () => {
    const matcher = new TeamMatcher();
    const awayMatch: Match = {
      matchId: 1001,
      team1Id: 50,
      team2Id: 122,
      team1Ar: "جنوب افريقيا",
      team1En: "South Africa",
      team2Ar: "مصر",
      team2En: "Egypt",
      kickoff: "2026-10-04T21:00:00",
      tournamentAr: "المباريات الودية الدولية.",
      tournamentEn: "International Friendlies.",
      stadiumAr: "استاد القاهرة الدولي",
      stadiumEn: "Cairo Int. Stadium",
      matchStatusRaw: 1,
      showInPortal: true,
      isDeleted: false,
      url: "https://tazkarti.com/",
    };

    const teams = matcher.identifyTeamsForMatch(awayMatch);
    assert.strictEqual(teams.length, 1);
    assert.strictEqual(teams[0].key, "egypt");
  });

  it("skips deleted and non-portal matches", () => {
    const matcher = new TeamMatcher();
    const deletedMatch: Match = {
      matchId: 1002,
      team1Ar: "مصر",
      team1En: "Egypt",
      team2Ar: "جنوب افريقيا",
      team2En: "South Africa",
      kickoff: "2026-10-04T21:00:00",
      tournamentAr: "بطولة",
      tournamentEn: "Tournament",
      stadiumAr: "استاد",
      stadiumEn: "Stadium",
      matchStatusRaw: 1,
      showInPortal: true,
      isDeleted: true, // DELETED
      url: "https://tazkarti.com/",
    };

    assert.strictEqual(matcher.identifyTeamsForMatch(deletedMatch).length, 0);

    const hiddenMatch = { ...deletedMatch, isDeleted: false, showInPortal: false };
    assert.strictEqual(matcher.identifyTeamsForMatch(hiddenMatch).length, 0);
  });
});
