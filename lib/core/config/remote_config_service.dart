import 'dart:io';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';

class RemoteConfigService {
  static const String keyIsCloakingActive = 'is_cloaking_active';
  static const String keyTargetOfferUrl = 'target_offer_url';

  final FirebaseRemoteConfig _remoteConfig = FirebaseRemoteConfig.instance;

  Future<void> initialize() async {
    try {
      await _remoteConfig.setConfigSettings(
        RemoteConfigSettings(
          fetchTimeout: const Duration(seconds: 8),
          minimumFetchInterval: const Duration(minutes: 10),
        ),
      );

      await _remoteConfig.setDefaults(<String, dynamic>{
        keyIsCloakingActive: false,
        keyTargetOfferUrl: '',
      });
    } catch (e, stack) {
      developer.log('RemoteConfig setDefaults failed: $e', stackTrace: stack, name: 'RemoteConfigService');
    }
  }

  /// Оновлення конфігурації з серверів Firebase
  Future<bool> fetchConfig() async {
    try {
      final updated = await _remoteConfig.fetchAndActivate();
      developer.log('RemoteConfig fetched successfully, updated: $updated', name: 'RemoteConfigService');
      return updated;
    } catch (e) {
      developer.log('RemoteConfig fetch error: $e', name: 'RemoteConfigService');
      return false;
    }
  }

  bool isCloakingActive() {
    try {
      return _remoteConfig.getBool(keyIsCloakingActive);
    } catch (_) {
      return false;
    }
  }

  String getTargetOfferUrl() {
    try {
      final url = _remoteConfig.getString(keyTargetOfferUrl).trim();
      return _isValidUrl(url) ? url : '';
    } catch (_) {
      return '';
    }
  }

  /// Перевірка активного підключення до мережі інтернет
  Future<bool> hasInternetConnection() async {
    if (kIsWeb) return true;
    try {
      final lookup = await InternetAddress.lookup('google.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup[0].rawAddress.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  bool _isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    final uri = Uri.tryParse(url);
    return uri != null && uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
  }
}
