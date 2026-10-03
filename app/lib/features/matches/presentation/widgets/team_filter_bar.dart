import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../matches_provider.dart';

class TeamFilterBar extends ConsumerWidget {
  const TeamFilterBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currentFilter = ref.watch(selectedTeamFilterProvider);

    final filters = [
      {'key': 'all', 'label': 'الكل', 'emoji': '⚽'},
      {'key': 'ahly', 'label': 'الأهلي', 'emoji': '🔴'},
      {'key': 'egypt', 'label': 'منتخب مصر', 'emoji': '🇪🇬'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        children: filters.map((f) {
          final isSelected = currentFilter == f['key'];
          return Padding(
            padding: const EdgeInsets.only(left: 8),
            child: ChoiceChip(
              showCheckmark: false,
              label: Text(
                '${f['emoji']} ${f['label']}',
                style: TextStyle(
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  color: isSelected ? Colors.white : Colors.white70,
                ),
              ),
              selected: isSelected,
              selectedColor: const Color(0xFFD32F2F),
              backgroundColor: const Color(0xFF1E2029),
              side: BorderSide(
                color: isSelected
                    ? const Color(0xFFD32F2F)
                    : const Color(0xFF2C2F3E),
              ),
              onSelected: (_) {
                ref.read(selectedTeamFilterProvider.notifier).state =
                    f['key']!;
              },
            ),
          );
        }).toList(),
      ),
    );
  }
}
