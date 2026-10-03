import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/constants/app_constants.dart';
import '../../../core/notifications/notification_service.dart';

class SettingsState {
  final bool subscribeAhly;
  final bool subscribeEgypt;
  final bool isLoaded;

  const SettingsState({
    this.subscribeAhly = true,
    this.subscribeEgypt = true,
    this.isLoaded = false,
  });

  SettingsState copyWith({
    bool? subscribeAhly,
    bool? subscribeEgypt,
    bool? isLoaded,
  }) {
    return SettingsState(
      subscribeAhly: subscribeAhly ?? this.subscribeAhly,
      subscribeEgypt: subscribeEgypt ?? this.subscribeEgypt,
      isLoaded: isLoaded ?? this.isLoaded,
    );
  }
}

class SettingsNotifier extends StateNotifier<SettingsState> {
  SettingsNotifier() : super(const SettingsState()) {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final ahly = prefs.getBool(AppConstants.prefSubscribeAhly) ?? true;
    final egypt = prefs.getBool(AppConstants.prefSubscribeEgypt) ?? true;

    // Ensure FCM subscription matches saved preferences on launch
    if (ahly) {
      await NotificationService().subscribeToTopic(AppConstants.topicAhly);
    }
    if (egypt) {
      await NotificationService().subscribeToTopic(AppConstants.topicEgypt);
    }

    state = SettingsState(
      subscribeAhly: ahly,
      subscribeEgypt: egypt,
      isLoaded: true,
    );
  }

  Future<void> toggleAhly(bool value) async {
    state = state.copyWith(subscribeAhly: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefSubscribeAhly, value);

    if (value) {
      await NotificationService().subscribeToTopic(AppConstants.topicAhly);
    } else {
      await NotificationService().unsubscribeFromTopic(AppConstants.topicAhly);
    }
  }

  Future<void> toggleEgypt(bool value) async {
    state = state.copyWith(subscribeEgypt: value);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(AppConstants.prefSubscribeEgypt, value);

    if (value) {
      await NotificationService().subscribeToTopic(AppConstants.topicEgypt);
    } else {
      await NotificationService().unsubscribeFromTopic(AppConstants.topicEgypt);
    }
  }
}

final settingsProvider =
    StateNotifierProvider<SettingsNotifier, SettingsState>((ref) {
  return SettingsNotifier();
});
