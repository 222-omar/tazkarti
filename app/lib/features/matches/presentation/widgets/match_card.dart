import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../data/match_model.dart';
import 'status_badge.dart';

class MatchCard extends StatelessWidget {
  final MatchModel match;

  const MatchCard({super.key, required this.match});

  Future<void> _openTazkarti() async {
    final uri = Uri.parse(match.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEgypt = match.isEgyptMatch;
    final isAhly = match.isAhlyMatch;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: const Color(0xFF181A22),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAhly
              ? const Color(0xFFD32F2F).withValues(alpha: 0.6)
              : isEgypt
                  ? const Color(0xFFC41230).withValues(alpha: 0.6)
                  : const Color(0xFF2C2F3E),
          width: 1.2,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Top Row: Tournament & Raw Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    match.tournamentAr.isNotEmpty
                        ? match.tournamentAr
                        : match.tournamentEn,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF9E9E9E),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                StatusBadge(statusRaw: match.matchStatusRaw),
              ],
            ),
            const Divider(color: Color(0xFF2C2F3E), height: 20),

            // Teams Row (Arabic & prominent)
            Row(
              children: [
                // Team 1
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamBadge(
                        match.team1Ar,
                        match.isAhlyMatch
                            ? '🔴'
                            : match.isEgyptMatch
                                ? '🇪🇬'
                                : '⚽',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.team1Ar.isNotEmpty
                            ? match.team1Ar
                            : match.team1En,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),

                // "VS" Badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF242632),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'ضد',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFFFFB800),
                    ),
                  ),
                ),

                // Team 2
                Expanded(
                  child: Column(
                    children: [
                      _buildTeamBadge(
                        match.team2Ar,
                        match.team2En.toLowerCase().contains('egypt')
                            ? '🇪🇬'
                            : match.team2En.toLowerCase().contains('ahly')
                                ? '🔴'
                                : '⚽',
                      ),
                      const SizedBox(height: 8),
                      Text(
                        match.team2Ar.isNotEmpty
                            ? match.team2Ar
                            : match.team2En,
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // Kickoff Info and Stadium
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF13141B),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today,
                          size: 14, color: Color(0xFFFFB800)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          match.formattedKickoffAr,
                          style: const TextStyle(
                            fontSize: 13,
                            color: Colors.white,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (match.stadiumAr.isNotEmpty) ...[
                    const SizedBox(height: 6),
                    Row(
                      children: [
                        const Icon(Icons.location_on_outlined,
                            size: 15, color: Color(0xFF9E9E9E)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            match.stadiumAr,
                            style: const TextStyle(
                              fontSize: 12,
                              color: Color(0xFFB0B0B0),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 14),

            // Action Button: Open Tazkarti
            SizedBox(
              width: double.infinity,
              height: 44,
              child: ElevatedButton.icon(
                onPressed: _openTazkarti,
                icon: const Icon(Icons.open_in_browser, size: 18),
                label: const Text(
                  'فتح موقع تذكرتي للحجز',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFD32F2F),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTeamBadge(String name, String emoji) {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: const Color(0xFF242632),
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFF383B4D), width: 1.5),
      ),
      child: Center(
        child: Text(
          emoji,
          style: const TextStyle(fontSize: 22),
        ),
      ),
    );
  }
}
