import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/match_model.dart';
import '../data/match_repository.dart';

final matchRepositoryProvider = Provider<MatchRepository>((ref) {
  return MatchRepository();
});

final matchesStreamProvider = StreamProvider<List<MatchModel>>((ref) async* {
  final repo = ref.watch(matchRepositoryProvider);
  try {
    await for (final matches in repo.watchMatches()) {
      if (matches.isEmpty) {
        // Fall back to sample live matches if Firestore collection has no items yet
        yield MatchRepository.fallbackMockMatches;
      } else {
        yield matches;
      }
    }
  } catch (error) {
    // If Firebase connection fails or is offline, show fallback matches
    yield MatchRepository.fallbackMockMatches;
  }
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
