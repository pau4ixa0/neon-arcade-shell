import 'dart:async';
import 'dart:developer' as developer;
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import '../constants/app_constants.dart';

class AnalyticsService {
  late AppsflyerSdk _appsflyerSdk;
  final Completer<Map<String, dynamic>> _conversionDataCompleter = Completer<Map<String, dynamic>>();

  AnalyticsService() {
    final AppsFlyerOptions options = AppsFlyerOptions(
      afDevKey: AppConstants.appsFlyerDevKey,
      appId: AppConstants.appsFlyerAppIdIos,
      showDebug: true,
      timeToWaitForATTUserAuthorization: 15,
    );

    _appsflyerSdk = AppsflyerSdk(options);
  }

  Future<void> init() async {
    try {
      _appsflyerSdk.onInstallConversionData((res) {
        developer.log('Conversion data received: $res', name: 'AnalyticsService');
        if (!_conversionDataCompleter.isCompleted) {
          final data = res['payload'] as Map<String, dynamic>? ?? {};
          _conversionDataCompleter.complete(data);
        }
      });

      _appsflyerSdk.onAppOpenAttribution((res) {
        developer.log('App open attribution: $res', name: 'AnalyticsService');
      });

      await _appsflyerSdk.initSdk(
        registerConversionDataCallback: true,
        registerOnAppOpenAttributionCallback: true,
        registerOnDeepLinkingCallback: true,
      );
    } catch (e) {
      developer.log('AppsFlyer init failed: $e', name: 'AnalyticsService');
      if (!_conversionDataCompleter.isCompleted) {
        _conversionDataCompleter.complete({});
      }
    }
  }

  Future<Map<String, dynamic>> getConversionDataWithTimeout({Duration timeout = const Duration(seconds: 4)}) async {
    try {
      return await _conversionDataCompleter.future.timeout(
        timeout,
        onTimeout: () {
          developer.log('Conversion data timed out, proceeding with defaults', name: 'AnalyticsService');
          return <String, dynamic>{};
        },
      );
    } catch (_) {
      return <String, dynamic>{};
    }
  }

  /// Формування розширеного URL оферу з передачею трекінг-параметрів
  Future<String> buildEnrichedUrl({
    required String baseUrl,
    required Map<String, dynamic> conversionData,
    String? fcmToken,
  }) async {
    try {
      final baseUri = Uri.parse(baseUrl);
      final appsFlyerUID = await _appsflyerSdk.getAppsFlyerUID() ?? '';

      final Map<String, String> queryParameters = Map<String, String>.from(baseUri.queryParameters);

      // 1. Атрибуція пристрою
      if (appsFlyerUID.isNotEmpty) {
        queryParameters['appsflyer_id'] = appsFlyerUID;
      }
      if (fcmToken != null && fcmToken.isNotEmpty) {
        queryParameters['push_token'] = fcmToken;
      }

      // 2. Дані рекламної кампанії
      final campaignKeys = ['campaign', 'campaign_id', 'media_source', 'af_status', 'adset', 'ad', 'ad_id', 'clickid'];
      for (final key in campaignKeys) {
        if (conversionData.containsKey(key) && conversionData[key] != null) {
          queryParameters[key] = conversionData[key].toString();
        }
      }

      // 3. Субаккаунти sub1 - sub10 та af_sub1 - af_sub5
      for (int i = 1; i <= 10; i++) {
        final subKey = 'sub$i';
        if (conversionData.containsKey(subKey) && conversionData[subKey] != null) {
          queryParameters[subKey] = conversionData[subKey].toString();
        }
      }

      for (int i = 1; i <= 5; i++) {
        final afSubKey = 'af_sub$i';
        if (conversionData.containsKey(afSubKey) && conversionData[afSubKey] != null) {
          queryParameters[afSubKey] = conversionData[afSubKey].toString();
        }
      }

      return baseUri.replace(queryParameters: queryParameters).toString();
    } catch (e) {
      developer.log('Error building enriched url: $e', name: 'AnalyticsService');
      return baseUrl;
    }
  }

  /// Трекінг реєстрації гравця
  Future<void> trackRegistration({String? userId}) async {
    await trackEvent('af_complete_registration', {
      if (userId != null) 'af_customer_user_id': userId,
      'registration_timestamp': DateTime.now().millisecondsSinceEpoch,
    });
  }

  /// Трекінг депозиту гравця (first_deposit або af_purchase)
  Future<void> trackDeposit({
    required double amount,
    required String currency,
    bool isFirstDeposit = false,
  }) async {
    final eventName = isFirstDeposit ? 'first_deposit' : 'af_purchase';
    await trackEvent(eventName, {
      'af_revenue': amount,
      'af_currency': currency,
      'is_first_deposit': isFirstDeposit,
    });
  }

  /// Універсальне логування кастомних подій
  Future<bool?> trackEvent(String eventName, [Map<String, dynamic>? eventValues]) async {
    try {
      return await _appsflyerSdk.logEvent(eventName, eventValues ?? {});
    } catch (e) {
      developer.log('Error logging event $eventName: $e', name: 'AnalyticsService');
      return false;
    }
  }
}
