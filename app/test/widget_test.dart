import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tazkarti_alert/features/matches/data/match_model.dart';
import 'package:tazkarti_alert/features/matches/presentation/widgets/status_badge.dart';

void main() {
  test('MatchModel parsing test', () {
    final rawData = {
      'matchId': 2601,
      'teamId1': 122,
      'teamId2': 67,
      'teamNameAr1': 'مصر',
      'teamName1': 'Egypt',
      'teamNameAr2': 'جنوب افريقيا',
      'teamName2': 'South Africa',
      'kickoff': '2026-10-04T21:00:00',
      'tournamentAr': 'المباريات الودية الدولية.',
      'tournamentEn': 'International Friendlies.',
      'stadiumAr': 'استاد القاهرة الدولي',
      'stadiumEn': 'Cairo Int. Stadium',
      'lastMatchStatusRaw': 1,
      'teamKeys': ['egypt'],
      'showInPortal': true,
      'isDeleted': false,
      'url': 'https://tazkarti.com/',
    };

    final match = MatchModel.fromFirestore(rawData);
    expect(match.matchId, 2601);
    expect(match.team1Ar, 'مصر');
    expect(match.team2Ar, 'جنوب افريقيا');
    expect(match.matchStatusRaw, 1);
    expect(match.isEgyptMatch, isTrue);
    expect(match.isAhlyMatch, isFalse);
  });

  testWidgets('StatusBadge displays raw status integer', (WidgetTester tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: StatusBadge(statusRaw: 1),
        ),
      ),
    );

    expect(find.text('الحالة (RAW): 1'), findsOneWidget);
  });
}
