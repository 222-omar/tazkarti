import 'dart:developer' as developer;
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';
import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'core/notifications/notification_service.dart';
import 'features/navigation/main_nav_scaffold.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase safely
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    developer.log('Firebase initialized successfully', name: 'Main');

    // Initialize notification service (channels, permissions, handlers)
    await NotificationService().initialize();
  } catch (e) {
    developer.log(
      'Notice: Firebase initialization deferred or demo mode active: $e',
      name: 'Main',
    );
  }

  runApp(const ProviderScope(child: TazkartiAlertApp()));
}

class TazkartiAlertApp extends StatelessWidget {
  const TazkartiAlertApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConstants.appTitle,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.darkTheme(),

      // RTL and Arabic by default
      locale: const Locale('ar'),
      supportedLocales: const [
        Locale('ar'),
        Locale('en'),
      ],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      home: const MainNavScaffold(),
    );
  }
}
