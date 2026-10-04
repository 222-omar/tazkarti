import 'package:cloud_firestore/cloud_firestore.dart';
import 'match_model.dart';

class MatchRepository {
  final FirebaseFirestore _firestore;

  MatchRepository({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  Stream<List<MatchModel>> watchMatches() {
    return _firestore.collection('matches').snapshots().map((snapshot) {
      final matches = snapshot.docs
          .map((doc) {
            try {
              return MatchModel.fromFirestore(doc.data());
            } catch (_) {
              return null;
            }
          })
          .whereType<MatchModel>()
          .where((m) => !m.isDeleted && m.showInPortal)
          .toList();

      // Sort by kickoff ascending (upcoming first)
      matches.sort((a, b) => a.kickoff.compareTo(b.kickoff));
      return matches;
    });
  }

  /// In-memory mock matches for instant testing before connecting live Firebase
  static List<MatchModel> get fallbackMockMatches => [
        MatchModel(
          matchId: 2601,
          team1Id: 122,
          team2Id: 67,
          team1Ar: 'مصر',
          team1En: 'Egypt',
          team2Ar: 'جنوب افريقيا',
          team2En: 'South Africa',
          kickoff: DateTime(2026, 10, 4, 21, 0),
          tournamentAr: 'المباريات الودية الدولية.',
          tournamentEn: 'International Friendlies.',
          stadiumAr: 'استاد القاهرة الدولي',
          stadiumEn: 'Cairo Int. Stadium',
          matchStatusRaw: 1,
          teamKeys: const ['egypt'],
          showInPortal: true,
          isDeleted: false,
          url: 'https://tazkarti.com/',
          maxTicketsPerUser: 4,
          gatesOpenTime: '2026-10-04T16:00:00',
        ),
        MatchModel(
          matchId: 3105,
          team1Id: 450,
          team2Id: 890,
          team1Ar: 'الأهلي',
          team1En: 'Al Ahly',
          team2Ar: 'ماميلودي صنداونز',
          team2En: 'Mamelodi Sundowns',
          kickoff: DateTime(2026, 10, 18, 20, 0),
          tournamentAr: 'دوري أبطال أفريقيا',
          tournamentEn: 'CAF Champions League',
          stadiumAr: 'استاد القاهرة الدولي',
          stadiumEn: 'Cairo Int. Stadium',
          matchStatusRaw: 1,
          teamKeys: const ['ahly'],
          showInPortal: true,
          isDeleted: false,
          url: 'https://tazkarti.com/',
          maxTicketsPerUser: 2,
        ),
      ];
}
