import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  developer.log('FCM Background message handled: ${message.messageId}', name: 'PushNotificationService');
}

class PushNotificationService {
  String? _fcmToken;
  FlutterLocalNotificationsPlugin? _localNotifications;

  String? get fcmToken => _fcmToken;

  Future<void> initialize() async {
    if (kIsWeb) {
      developer.log('Push notifications are skipped in web mode', name: 'PushNotificationService');
      return;
    }

    try {
      final fcm = FirebaseMessaging.instance;
      _localNotifications = FlutterLocalNotificationsPlugin();

      // 1. Запит дозволів на пуш-сповіщення (Android 13+ POST_NOTIFICATIONS та iOS)
      final NotificationSettings settings = await fcm.requestPermission(
        alert: true,
        announcement: false,
        badge: true,
        carPlay: false,
        criticalAlert: false,
        provisional: false,
        sound: true,
      );

      developer.log('FCM Authorization status: ${settings.authorizationStatus}', name: 'PushNotificationService');

      // 2. Ініціалізація локальних сповіщень для показу у Foreground
      const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
      const DarwinInitializationSettings iosSettings = DarwinInitializationSettings(
        requestAlertPermission: false,
        requestBadgePermission: false,
        requestSoundPermission: false,
      );
      const InitializationSettings initSettings = InitializationSettings(
        android: androidSettings,
        iOS: iosSettings,
      );

      await _localNotifications?.initialize(initSettings);

      // Створення високопріоритетного каналу сповіщень для Android
      const AndroidNotificationChannel channel = AndroidNotificationChannel(
        'igaming_promo_channel',
        'Promotions & Bonuses',
        description: 'Special bonus and event notifications',
        importance: Importance.max,
      );

      await _localNotifications
          ?.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(channel);

      // 3. Отримання унікального токена FCM
      _fcmToken = await fcm.getToken();
      developer.log('FCM Device Token: $_fcmToken', name: 'PushNotificationService');

      // 4. Підписка на топік для загальних маркетингових розсилок
      await subscribeToTopic('all_users');

      // 5. Отримання сповіщень у стані Foreground
      FirebaseMessaging.onMessage.listen((RemoteMessage message) {
        developer.log('Foreground push received: ${message.notification?.title}', name: 'PushNotificationService');
        _showForegroundNotification(message);
      });

      // 6. Обробка кліку на сповіщення, коли додаток у бекграунді (Background state)
      FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
        developer.log('Notification tapped from background: ${message.data}', name: 'PushNotificationService');
      });

      // 7. Обробка запуску додатку через клік на сповіщення із закритого стану (Terminated state)
      final RemoteMessage? initialMessage = await fcm.getInitialMessage();
      if (initialMessage != null) {
        developer.log('App opened from terminated state via notification: ${initialMessage.data}', name: 'PushNotificationService');
      }
    } catch (e) {
      developer.log('Push notification service initialized with notice: $e', name: 'PushNotificationService');
    }
  }

  Future<void> subscribeToTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.subscribeToTopic(topic);
      developer.log('Subscribed to topic: $topic', name: 'PushNotificationService');
    } catch (e) {
      developer.log('Failed to subscribe to topic $topic: $e', name: 'PushNotificationService');
    }
  }

  Future<void> unsubscribeFromTopic(String topic) async {
    if (kIsWeb) return;
    try {
      await FirebaseMessaging.instance.unsubscribeFromTopic(topic);
      developer.log('Unsubscribed from topic: $topic', name: 'PushNotificationService');
    } catch (e) {
      developer.log('Failed to unsubscribe from topic $topic: $e', name: 'PushNotificationService');
    }
  }

  Future<void> _showForegroundNotification(RemoteMessage message) async {
    if (kIsWeb || _localNotifications == null) return;
    final notification = message.notification;
    if (notification == null) return;

    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'igaming_promo_channel',
      'Promotions & Bonuses',
      importance: Importance.max,
      priority: Priority.high,
      showWhen: true,
    );

    const NotificationDetails platformDetails = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(
        presentAlert: true,
        presentBadge: true,
        presentSound: true,
      ),
    );

    await _localNotifications?.show(
      message.hashCode,
      notification.title ?? '',
      notification.body ?? '',
      platformDetails,
    );
  }
}
