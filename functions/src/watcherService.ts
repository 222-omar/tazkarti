import * as admin from "firebase-admin";
import { CONFIG } from "./config";
import { fetchMatches, Match } from "./tazkartiClient";
import { TeamMatcher, MatchedTeamResult } from "./matcher";
import { sendMatchNotification, sendAdminAlert } from "./notifier";

export interface StoredMatchDoc {
  matchId: number;
  teamKeys: string[];
  lastMatchStatusRaw: number;
  firstSeenAt: string;
  updatedAt: string;
  notifiedNew: boolean;
  lastNotifiedStatus: number;
  // Match fields
  team1Id: number | null;
  team2Id: number | null;
  team1Ar: string;
  team1En: string;
  team2Ar: string;
  team2En: string;
  kickoff: string;
  tournamentAr: string;
  tournamentEn: string;
  stadiumAr: string;
  stadiumEn: string;
  showInPortal: boolean;
  isDeleted: boolean;
  url: string;
  team1Logo?: string | null;
  team2Logo?: string | null;
  maxTicketsPerUser?: number | null;
  gatesOpenTime?: string | null;
}

export class WatcherService {
  private matcher: TeamMatcher;
  private db: admin.firestore.Firestore;

  constructor() {
    this.matcher = new TeamMatcher();
    this.db = admin.firestore();
  }

  /**
   * Main polling routine called on schedule or on-demand.
   */
  public async runPoll(): Promise<{
    matchesCount: number;
    trackedMatchesCount: number;
    notificationsSent: number;
  }> {
    let notificationsSent = 0;
    try {
      const matches = await fetchMatches();
      await this.recordHealthSuccess();

      // Check if this is the very first seeding run
      const isFirstRun = await this.checkAndHandleFirstRunSeeding(matches);

      // Filter matches to those that belong to tracked teams
      const trackedMatchesWithTeams: Array<{
        match: Match;
        matchedTeams: MatchedTeamResult[];
      }> = [];

      for (const m of matches) {
        const teams = this.matcher.identifyTeamsForMatch(m);
        if (teams.length > 0) {
          trackedMatchesWithTeams.push({ match: m, matchedTeams: teams });
        }
      }

      console.log(
        `[Watcher] Found ${matches.length} total matches from Tazkarti, ${trackedMatchesWithTeams.length} belong to tracked teams.`
      );

      // If initial silent seeding is underway, we write docs without sending notifications
      if (isFirstRun && CONFIG.seedSilently) {
        console.log("[Watcher] SEED_SILENTLY is active: saving current matches without dispatching alerts.");
        for (const item of trackedMatchesWithTeams) {
          await this.saveMatchDoc(item.match, item.matchedTeams, {
            notifiedNew: true,
            lastNotifiedStatus: item.match.matchStatusRaw,
          });
        }
        return {
          matchesCount: matches.length,
          trackedMatchesCount: trackedMatchesWithTeams.length,
          notificationsSent: 0,
        };
      }

      // Normal execution: compare with stored state and detect transitions
      for (const item of trackedMatchesWithTeams) {
        const { match, matchedTeams } = item;
        const matchRef = this.db.collection(CONFIG.matchesCollection).doc(String(match.matchId));
        const docSnap = await matchRef.get();

        if (!docSnap.exists) {
          // (a) NEW MATCH TRANSITION
          console.log(
            `[TRANSITION: NEW MATCH] Detected new match: #${match.matchId} (${match.team1Ar} vs ${match.team2Ar})`
          );

          // Dispatch notification to each matched team's topic
          for (const team of matchedTeams) {
            try {
              await sendMatchNotification({
                topic: team.topic,
                teamKey: team.key,
                teamDisplayAr: team.displayAr,
                match,
                transitionType: "NEW_MATCH",
              });
              notificationsSent++;
            } catch (err) {
              console.error(`Error notifying team ${team.key} for match ${match.matchId}:`, err);
            }
          }

          await this.saveMatchDoc(match, matchedTeams, {
            notifiedNew: true,
            lastNotifiedStatus: match.matchStatusRaw,
          });
        } else {
          // Document exists, check for raw matchStatus changes
          const existing = docSnap.data() as StoredMatchDoc;
          const oldStatus = existing.lastMatchStatusRaw;
          const newStatus = match.matchStatusRaw;

          if (oldStatus !== newStatus && existing.lastNotifiedStatus !== newStatus) {
            // (b) STATUS CHANGED TRANSITION
            console.log(
              `[TRANSITION: STATUS CHANGED] Match #${match.matchId} raw status transitioned: ${oldStatus} -> ${newStatus}`
            );

            for (const team of matchedTeams) {
              try {
                await sendMatchNotification({
                  topic: team.topic,
                  teamKey: team.key,
                  teamDisplayAr: team.displayAr,
                  match,
                  transitionType: "STATUS_CHANGED",
                });
                notificationsSent++;
              } catch (err) {
                console.error(`Error notifying status change for match ${match.matchId}:`, err);
              }
            }

            await this.saveMatchDoc(match, matchedTeams, {
              notifiedNew: true,
              lastNotifiedStatus: newStatus,
            });
          } else {
            // No transition, just update latest timestamp and details quietly
            await this.updateMatchDocQuietly(match, matchedTeams);
          }
        }
      }

      return {
        matchesCount: matches.length,
        trackedMatchesCount: trackedMatchesWithTeams.length,
        notificationsSent,
      };
    } catch (err: any) {
      console.error("[Watcher] Poll execution failed:", err);
      await this.recordHealthFailure(err.message || String(err));
      throw err;
    }
  }

  /**
   * Checks whether the global watcher state has been initialized.
   * If not, sets isSeeded=true and returns true.
   */
  private async checkAndHandleFirstRunSeeding(matches: Match[]): Promise<boolean> {
    const stateRef = this.db.collection(CONFIG.watcherStateCollection).doc("global");
    const stateSnap = await stateRef.get();

    if (!stateSnap.exists || !stateSnap.data()?.isSeeded) {
      await stateRef.set(
        {
          isSeeded: true,
          seededAt: admin.firestore.FieldValue.serverTimestamp(),
          initialMatchCount: matches.length,
        },
        { merge: true }
      );
      return true;
    }
    return false;
  }

  private async saveMatchDoc(
    match: Match,
    matchedTeams: MatchedTeamResult[],
    flags: { notifiedNew: boolean; lastNotifiedStatus: number }
  ): Promise<void> {
    const matchRef = this.db.collection(CONFIG.matchesCollection).doc(String(match.matchId));
    const now = new Date().toISOString();

    const data: StoredMatchDoc = {
      matchId: match.matchId,
      teamKeys: matchedTeams.map((t) => t.key),
      lastMatchStatusRaw: match.matchStatusRaw,
      firstSeenAt: now,
      updatedAt: now,
      notifiedNew: flags.notifiedNew,
      lastNotifiedStatus: flags.lastNotifiedStatus,
      team1Id: match.team1Id ?? null,
      team2Id: match.team2Id ?? null,
      team1Ar: match.team1Ar,
      team1En: match.team1En,
      team2Ar: match.team2Ar,
      team2En: match.team2En,
      kickoff: match.kickoff,
      tournamentAr: match.tournamentAr,
      tournamentEn: match.tournamentEn,
      stadiumAr: match.stadiumAr,
      stadiumEn: match.stadiumEn,
      showInPortal: match.showInPortal,
      isDeleted: match.isDeleted,
      url: match.url,
      team1Logo: match.team1Logo,
      team2Logo: match.team2Logo,
      maxTicketsPerUser: match.maxTicketsPerUser,
      gatesOpenTime: match.gatesOpenTime,
    };

    await matchRef.set(data, { merge: true });
  }

  private async updateMatchDocQuietly(
    match: Match,
    matchedTeams: MatchedTeamResult[]
  ): Promise<void> {
    const matchRef = this.db.collection(CONFIG.matchesCollection).doc(String(match.matchId));
    await matchRef.set(
      {
        lastMatchStatusRaw: match.matchStatusRaw,
        teamKeys: matchedTeams.map((t) => t.key),
        updatedAt: new Date().toISOString(),
        showInPortal: match.showInPortal,
        isDeleted: match.isDeleted,
        stadiumAr: match.stadiumAr,
        tournamentAr: match.tournamentAr,
        kickoff: match.kickoff,
      },
      { merge: true }
    );
  }

  /**
   * Health recording and failure alerting
   */
  private async recordHealthSuccess(): Promise<void> {
    const healthRef = this.db.collection(CONFIG.watcherStateCollection).doc("health");
    const snap = await healthRef.get();
    const data = snap.data();

    if (data && data.consecutiveFailures >= CONFIG.failureAlertThreshold && data.hasAlerted) {
      // Send recovery notification
      await sendAdminAlert(
        "تم استعادة الاتصال بنجاح",
        "نجح النظام في سحب بيانات تذكرتي والتحقق من بنيتها بشكل سليم بعد انقطاع."
      );
    }

    await healthRef.set({
      consecutiveFailures: 0,
      hasAlerted: false,
      lastSuccessAt: admin.firestore.FieldValue.serverTimestamp(),
      lastError: null,
    });
  }

  private async recordHealthFailure(errorMessage: string): Promise<void> {
    const healthRef = this.db.collection(CONFIG.watcherStateCollection).doc("health");
    const snap = await healthRef.get();
    const current = snap.exists ? (snap.data()?.consecutiveFailures || 0) : 0;
    const hasAlerted = snap.exists ? Boolean(snap.data()?.hasAlerted) : false;
    const newCount = current + 1;

    let shouldAlert = false;
    if (newCount >= CONFIG.failureAlertThreshold && !hasAlerted) {
      shouldAlert = true;
    }

    await healthRef.set(
      {
        consecutiveFailures: newCount,
        hasAlerted: hasAlerted || shouldAlert,
        lastFailureAt: admin.firestore.FieldValue.serverTimestamp(),
        lastError: errorMessage,
      },
      { merge: true }
    );

    if (shouldAlert) {
      console.warn(`[Health] Failure threshold reached (${newCount} failures in a row). Sending admin alert.`);
      await sendAdminAlert(
        "فشل متكرر في الاتصال بـ Tazkarti",
        `فشل الاتصال أو التحقق من شكل البيانات ${newCount} مرات متتالية. الخطأ الأخير: ${errorMessage}`
      );
    }
  }

  /**
   * Test notification utility: forces an immediate test notification for Egypt or Ahly match.
   */
  public async triggerTestNotification(targetTeamKey: string = "egypt"): Promise<{
    success: boolean;
    messageId?: string;
  }> {
    const matches = await fetchMatches();
    let targetMatch: Match | undefined;

    for (const m of matches) {
      const teams = this.matcher.identifyTeamsForMatch(m);
      if (teams.some((t) => t.key === targetTeamKey)) {
        targetMatch = m;
        break;
      }
    }

    if (!targetMatch) {
      // Create a mock match for testing
      targetMatch = {
        matchId: 2601,
        team1Id: 122,
        team2Id: 67,
        team1Ar: targetTeamKey === "egypt" ? "مصر" : "الأهلي",
        team1En: targetTeamKey === "egypt" ? "Egypt" : "Al Ahly",
        team2Ar: "جنوب افريقيا",
        team2En: "South Africa",
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
    }

    const topic = targetTeamKey === "egypt" ? "egypt_tickets" : "ahly_tickets";
    const displayAr = targetTeamKey === "egypt" ? "منتخب مصر" : "الأهلي";

    const messageId = await sendMatchNotification({
      topic,
      teamKey: targetTeamKey,
      teamDisplayAr: displayAr,
      match: targetMatch,
      transitionType: "NEW_MATCH",
    });

    return { success: true, messageId };
  }
}
