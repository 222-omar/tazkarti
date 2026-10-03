import 'dart:developer' as developer;
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../constants/app_constants.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // Ensure Firebase is initialized for background message handler
  await Firebase.initializeApp();
  developer.log(
    'Handling background message: ${message.messageId}, data: ${message.data}',
    name: 'NotificationService',
  );
}

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FirebaseMessaging _fcm = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const AndroidNotificationChannel _highPriorityChannel =
      AndroidNotificationChannel(
    AppConstants.notificationChannelId,
    AppConstants.notificationChannelName,
    description: AppConstants.notificationChannelDesc,
    importance: Importance.max,
    playSound: true,
    enableVibration: true,
    showBadge: true,
  );

  Future<void> initialize() async {
    // 1. Request permissions for Android 13+ and iOS
    await _requestPermissions();

    // 2. Initialize Flutter Local Notifications for foreground popups
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (NotificationResponse response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          _openUrl(response.payload!);
        } else {
          _openUrl(AppConstants.tazkartiUrl);
        }
      },
    );

    // 3. Create high importance notification channel on Android
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.createNotificationChannel(_highPriorityChannel);
    }

    // 4. Configure foreground presentation options for iOS
    await _fcm.setForegroundNotificationPresentationOptions(
      alert: true,
      badge: true,
      sound: true,
    );

    // 5. Setup foreground message listener
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      developer.log('Received foreground message: ${message.messageId}',
          name: 'NotificationService');
      _showForegroundNotification(message);
    });

    // 6. Handle notification click when app is opened from background
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      developer.log('App opened from background via notification: ${message.data}',
          name: 'NotificationService');
      final url = message.data['url'] ?? AppConstants.tazkartiUrl;
      _openUrl(url);
    });

    // 7. Check if app was opened from terminated state via notification click
    final initialMessage = await _fcm.getInitialMessage();
    if (initialMessage != null) {
      developer.log('App launched from terminated state via notification: ${initialMessage.data}',
          name: 'NotificationService');
      final url = initialMessage.data['url'] ?? AppConstants.tazkartiUrl;
      _openUrl(url);
    }

    // Set background message handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);

    // Auto-alert for Egypt match on first launch / permission grant!
    await _sendInitialEgyptMatchAlertIfFirstTime();
  }

  Future<void> _sendInitialEgyptMatchAlertIfFirstTime() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final alreadySent = prefs.getBool('has_sent_welcome_egypt_alert') ?? false;
      if (!alreadySent) {
        // Trigger right after user accepts permission dialog
        Future.delayed(const Duration(milliseconds: 1500), () async {
          await showTestNotification(
            title: '🇪🇬 مباراة جديدة لـ منتخب مصر',
            body: 'مصر vs جنوب افريقيا - الأحد 4 أكتوبر 2026 - 09:00 م',
          );
          await prefs.setBool('has_sent_welcome_egypt_alert', true);
        });
      }
    } catch (e) {
      developer.log('Error triggering initial Egypt alert: $e', name: 'NotificationService');
    }
  }

  Future<void> _requestPermissions() async {
    // Firebase Messaging permission (iOS and Android 13+)
    final settings = await _fcm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );
    developer.log('Notification permission status: ${settings.authorizationStatus}',
        name: 'NotificationService');

    // Android 13+ local notifications permission request
    final androidPlugin = _localNotifications
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();
    if (androidPlugin != null) {
      await androidPlugin.requestNotificationsPermission();
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    final notification = message.notification;
    final data = message.data;

    final title = notification?.title ?? data['title'] ?? '🔴 تذاكر جديدة على تذكرتي!';
    final body = notification?.body ?? data['body'] ?? 'تم تحديث تذاكر المباراة، اضغط للحجز الآن.';
    final url = data['url'] ?? AppConstants.tazkartiUrl;

    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      message.hashCode,
      title,
      body,
      notificationDetails,
      payload: url,
    );
  }

  /// Triggers a test heads-up notification immediately on the phone
  Future<void> showTestNotification({
    String title = '🇪🇬 مباراة جديدة لـ منتخب مصر',
    String body = 'مصر vs جنوب افريقيا - الأحد 4 أكتوبر 2026 - 09:00 م',
  }) async {
    const androidDetails = AndroidNotificationDetails(
      AppConstants.notificationChannelId,
      AppConstants.notificationChannelName,
      channelDescription: AppConstants.notificationChannelDesc,
      importance: Importance.max,
      priority: Priority.high,
      playSound: true,
      enableVibration: true,
      visibility: NotificationVisibility.public,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const notificationDetails = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _localNotifications.show(
      DateTime.now().millisecond,
      title,
      body,
      notificationDetails,
      payload: AppConstants.tazkartiUrl,
    );
  }

  Future<void> subscribeToTopic(String topic) async {
    try {
      await _fcm.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'NotificationService');
    } catch (e) {
      developer.log('Failed to subscribe to topic $topic: $e',
          name: 'NotificationService');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    try {
      await _fcm.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic',
          name: 'NotificationService');
    } catch (e) {
      developer.log('Failed to unsubscribe from topic $topic: $e',
          name: 'NotificationService');
    }
  }

  Future<void> _openUrl(String urlString) async {
    try {
      final uri = Uri.parse(urlString);
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      developer.log('Could not launch URL $urlString: $e',
          name: 'NotificationService');
    }
  }
}
