import 'package:intl/intl.dart';

class MatchModel {
  final int matchId;
  final int? team1Id;
  final int? team2Id;
  final String team1Ar;
  final String team1En;
  final String team2Ar;
  final String team2En;
  final DateTime kickoff;
  final String tournamentAr;
  final String tournamentEn;
  final String stadiumAr;
  final String stadiumEn;
  final int matchStatusRaw;
  final List<String> teamKeys;
  final bool showInPortal;
  final bool isDeleted;
  final String url;
  final String? team1Logo;
  final String? team2Logo;
  final int? maxTicketsPerUser;
  final String? gatesOpenTime;

  const MatchModel({
    required this.matchId,
    this.team1Id,
    this.team2Id,
    required this.team1Ar,
    required this.team1En,
    required this.team2Ar,
    required this.team2En,
    required this.kickoff,
    required this.tournamentAr,
    required this.tournamentEn,
    required this.stadiumAr,
    required this.stadiumEn,
    required this.matchStatusRaw,
    required this.teamKeys,
    required this.showInPortal,
    required this.isDeleted,
    required this.url,
    this.team1Logo,
    this.team2Logo,
    this.maxTicketsPerUser,
    this.gatesOpenTime,
  });

  factory MatchModel.fromFirestore(Map<String, dynamic> data) {
    DateTime parseKickoff(dynamic val) {
      if (val is String && val.isNotEmpty) {
        try {
          return DateTime.parse(val);
        } catch (_) {}
      }
      return DateTime.now();
    }

    int parseStatus(Map<String, dynamic> d) {
      if (d['lastMatchStatusRaw'] is int) return d['lastMatchStatusRaw'] as int;
      if (d['matchStatus'] is int) return d['matchStatus'] as int;
      if (d['matchStatusRaw'] is int) return d['matchStatusRaw'] as int;
      final str = '${d['lastMatchStatusRaw'] ?? d['matchStatus'] ?? d['matchStatusRaw']}';
      return int.tryParse(str) ?? 0;
    }

    final keys = (data['teamKeys'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];

    return MatchModel(
      matchId: (data['matchId'] is int)
          ? data['matchId'] as int
          : int.tryParse('${data['matchId']}') ?? 0,
      team1Id: (data['team1Id'] ?? data['teamId1']) as int?,
      team2Id: (data['team2Id'] ?? data['teamId2']) as int?,
      team1Ar: (data['team1Ar'] ?? data['teamNameAr1']) as String? ?? '',
      team1En: (data['team1En'] ?? data['teamName1']) as String? ?? '',
      team2Ar: (data['team2Ar'] ?? data['teamNameAr2']) as String? ?? '',
      team2En: (data['team2En'] ?? data['teamName2']) as String? ?? '',
      kickoff: parseKickoff(data['kickoff'] ?? data['kickOffTime']),
      tournamentAr: (data['tournamentAr'] ??
              (data['tournament'] is Map ? data['tournament']['nameAr'] : ''))
          as String? ??
          '',
      tournamentEn: (data['tournamentEn'] ??
              (data['tournament'] is Map ? data['tournament']['nameEn'] : ''))
          as String? ??
          '',
      stadiumAr: (data['stadiumAr'] ?? data['stadiumNameAr']) as String? ?? '',
      stadiumEn: (data['stadiumEn'] ?? data['stadiumName']) as String? ?? '',
      matchStatusRaw: parseStatus(data),
      teamKeys: keys,
      showInPortal: data['showInPortal'] as bool? ?? true,
      isDeleted: data['isDeleted'] as bool? ?? false,
      url: data['url'] as String? ?? 'https://tazkarti.com/',
      team1Logo: data['team1Logo'] as String?,
      team2Logo: data['team2Logo'] as String?,
      maxTicketsPerUser: data['maxTicketsPerUser'] as int?,
      gatesOpenTime: data['gatesOpenTime'] as String?,
    );
  }

  String get formattedKickoffAr {
    // Example: الأحد 4 أكتوبر 2026 - 09:00 م
    try {
      final formatter = DateFormat('EEEE d MMMM yyyy - hh:mm a', 'ar');
      return formatter.format(kickoff);
    } catch (_) {
      return DateFormat('yyyy-MM-dd HH:mm').format(kickoff);
    }
  }

  bool get isAhlyMatch => teamKeys.contains('ahly');
  bool get isEgyptMatch => teamKeys.contains('egypt');
}
