import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import 'core/analytics/analytics_service.dart';
import 'core/config/remote_config_service.dart';
import 'core/notifications/push_notification_service.dart';
import 'core/security/security_service.dart';
import 'core/storage/local_storage_service.dart';
import 'features/fallback_game/presentation/game_screen.dart';
import 'features/splash/presentation/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Для веб-браузера запускаємо гру безпосередньо, минаючи мобільні SDK
  if (kIsWeb) {
    runApp(MaterialApp(
      title: 'Neon Flappy Arcade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        useMaterial3: true,
      ),
      home: const GameScreen(),
    ));
    return;
  }

  // Нативний мобільний запуск (Android / iOS)
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  try {
    await Firebase.initializeApp();
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  } catch (e) {
    debugPrint('Firebase initialization notice: $e');
  }

  final localStorageService = await LocalStorageService.getInstance();
  final remoteConfigService = RemoteConfigService();
  final analyticsService = AnalyticsService();
  final pushNotificationService = PushNotificationService();
  final securityService = SecurityService();

  await securityService.enableScreenProtection();
  await pushNotificationService.initialize();

  runApp(AppRoot(
    localStorageService: localStorageService,
    remoteConfigService: remoteConfigService,
    analyticsService: analyticsService,
    pushNotificationService: pushNotificationService,
    securityService: securityService,
  ));
}

class AppRoot extends StatelessWidget {
  final LocalStorageService localStorageService;
  final RemoteConfigService remoteConfigService;
  final AnalyticsService analyticsService;
  final PushNotificationService pushNotificationService;
  final SecurityService securityService;

  const AppRoot({
    super.key,
    required this.localStorageService,
    required this.remoteConfigService,
    required this.analyticsService,
    required this.pushNotificationService,
    required this.securityService,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Neon Flappy Arcade',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0F0F1A),
        useMaterial3: true,
      ),
      home: SplashScreen(
        securityService: securityService,
        localStorageService: localStorageService,
        remoteConfigService: remoteConfigService,
        analyticsService: analyticsService,
        pushNotificationService: pushNotificationService,
      ),
    );
  }
}
