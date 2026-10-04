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

    int? toInt(dynamic val) {
      if (val == null) return null;
      if (val is int) return val;
      if (val is num) return val.toInt();
      return int.tryParse(val.toString());
    }

    int parseStatus(Map<String, dynamic> d) {
      final s = toInt(d['lastMatchStatusRaw']) ??
          toInt(d['matchStatus']) ??
          toInt(d['matchStatusRaw']);
      return s ?? 0;
    }

    final keys = (data['teamKeys'] as List<dynamic>?)
            ?.map((e) => e.toString().toLowerCase().trim())
            .toList() ??
        [];

    return MatchModel(
      matchId: toInt(data['matchId']) ?? 0,
      team1Id: toInt(data['team1Id'] ?? data['teamId1']),
      team2Id: toInt(data['team2Id'] ?? data['teamId2']),
      team1Ar: (data['team1Ar'] ?? data['teamNameAr1'] ?? '').toString(),
      team1En: (data['team1En'] ?? data['teamName1'] ?? '').toString(),
      team2Ar: (data['team2Ar'] ?? data['teamNameAr2'] ?? '').toString(),
      team2En: (data['team2En'] ?? data['teamName2'] ?? '').toString(),
      kickoff: parseKickoff(data['kickoff'] ?? data['kickOffTime']),
      tournamentAr: (data['tournamentAr'] ??
              (data['tournament'] is Map ? data['tournament']['nameAr'] : ''))
          ?.toString() ??
          '',
      tournamentEn: (data['tournamentEn'] ??
              (data['tournament'] is Map ? data['tournament']['nameEn'] : ''))
          ?.toString() ??
          '',
      stadiumAr: (data['stadiumAr'] ?? data['stadiumNameAr'] ?? '').toString(),
      stadiumEn: (data['stadiumEn'] ?? data['stadiumName'] ?? '').toString(),
      matchStatusRaw: parseStatus(data),
      teamKeys: keys,
      showInPortal: data['showInPortal'] != false,
      isDeleted: data['isDeleted'] == true,
      url: (data['url'] ?? 'https://tazkarti.com/').toString(),
      team1Logo: data['team1Logo']?.toString(),
      team2Logo: data['team2Logo']?.toString(),
      maxTicketsPerUser: toInt(data['maxTicketsPerUser']),
      gatesOpenTime: data['gatesOpenTime']?.toString(),
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
