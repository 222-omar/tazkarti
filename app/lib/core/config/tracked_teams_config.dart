import 'package:flutter/material.dart';

class TrackedTeamConfig {
  final String key;
  final String topic;
  final String nameAr;
  final String emoji;
  final Color primaryColor;
  final String prefKey;

  const TrackedTeamConfig({
    required this.key,
    required this.topic,
    required this.nameAr,
    required this.emoji,
    required this.primaryColor,
    required this.prefKey,
  });
}

class TrackedTeamsRegistry {
  static const TrackedTeamConfig ahly = TrackedTeamConfig(
    key: 'ahly',
    topic: 'ahly_tickets',
    nameAr: 'الأهلي',
    emoji: '🔴',
    primaryColor: Color(0xFFE50914),
    prefKey: 'pref_subscribe_ahly',
  );

  static const TrackedTeamConfig egypt = TrackedTeamConfig(
    key: 'egypt',
    topic: 'egypt_tickets',
    nameAr: 'منتخب مصر',
    emoji: '🇪🇬',
    primaryColor: Color(0xFFC41230),
    prefKey: 'pref_subscribe_egypt',
  );

  static const List<TrackedTeamConfig> teams = [ahly, egypt];

  static TrackedTeamConfig? fromKey(String key) {
    for (final t in teams) {
      if (t.key == key) return t;
    }
    return null;
  }
}
