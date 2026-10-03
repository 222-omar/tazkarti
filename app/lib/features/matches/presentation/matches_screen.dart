import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'matches_provider.dart';
import 'widgets/match_card.dart';
import 'widgets/team_filter_bar.dart';

class MatchesScreen extends ConsumerWidget {
  const MatchesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final matchesAsync = ref.watch(filteredMatchesProvider);

    return Scaffold(
      appBar: AppBar(
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10,
              height: 10,
              decoration: const BoxDecoration(
                color: Color(0xFF00E676),
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'تنبيهات تذاكر المباريات',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          // Filter Chips (All, Al Ahly, Egypt)
          const TeamFilterBar(),

          // Status Banner
          Container(
            width: double.infinity,
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E2029),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFF2C2F3E)),
            ),
            child: const Row(
              children: [
                Icon(Icons.bolt, color: Color(0xFFFFB800), size: 18),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'الرادار نشط: يتم إرسال إشعار فوري بمجرد ظهور التذاكر أو تحديث حالتها.',
                    style: TextStyle(
                      fontSize: 12,
                      color: Color(0xFFCCCCCC),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 6),

          // Matches List
          Expanded(
            child: RefreshIndicator(
              color: const Color(0xFFD32F2F),
              onRefresh: () async {
                ref.invalidate(matchesStreamProvider);
              },
              child: matchesAsync.when(
                data: (matches) {
                  if (matches.isEmpty) {
                    return _buildEmptyState();
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.only(bottom: 24, top: 4),
                    itemCount: matches.length,
                    itemBuilder: (context, index) {
                      return MatchCard(match: matches[index]);
                    },
                  );
                },
                loading: () => const Center(
                  child: CircularProgressIndicator(color: Color(0xFFD32F2F)),
                ),
                error: (err, stack) => _buildErrorState(ref, err.toString()),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: const Color(0xFF1E2029),
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF2C2F3E)),
                ),
                child: const Icon(
                  Icons.sports_soccer,
                  size: 40,
                  color: Color(0xFF9E9E9E),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'لا توجد مباريات معروضة حالياً',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'الرادار يتابع موقع تذكرتي كل دقيقة، وسيصلك إشعار فوري على شاشة الهاتف فور إضافة التذاكر.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  color: Color(0xFF9E9E9E),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorState(WidgetRef ref, String error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.cloud_off, size: 48, color: Color(0xFFD32F2F)),
            const SizedBox(height: 12),
            const Text(
              'تعذر جلب المباريات من الخادم',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 6),
            Text(
              error,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, color: Color(0xFF9E9E9E)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref.invalidate(matchesStreamProvider),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }
}
