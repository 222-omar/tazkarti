import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/match_model.dart';
import '../data/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

final matchesStreamProvider = StreamProvider<List<MatchModel>>((ref) {
  final repo = ref.watch(matchRepositoryProvider);
  return repo.watchMatches().handleError((error) {
    // If Firebase is not yet linked or offline, fall back to mock data
    return MatchRepository.fallbackMockMatches;
  });
});

/// Filter state: 'all' (الكل), 'ahly' (الأهلي), 'egypt' (منتخب مصر)
final selectedTeamFilterProvider = StateProvider<String>((ref) => 'all');

final filteredMatchesProvider = Provider<AsyncValue<List<MatchModel>>>((ref) {
  final matchesAsync = ref.watch(matchesStreamProvider);
  final filter = ref.watch(selectedTeamFilterProvider);

  return matchesAsync.whenData((matches) {
    if (filter == 'all') {
      return matches;
    }
    return matches.where((m) => m.teamKeys.contains(filter)).toList();
  });
});
