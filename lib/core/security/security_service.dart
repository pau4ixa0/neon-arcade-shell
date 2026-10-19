import 'dart:io';
import 'dart:developer' as developer;
import 'package:device_info_plus/device_info_plus.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_windowmanager/flutter_windowmanager.dart';

class SecurityService {
  final DeviceInfoPlugin _deviceInfo = DeviceInfoPlugin();

  /// Активує захист від скріншотів і запису екрана (FLAG_SECURE на Android)
  Future<void> enableScreenProtection() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
        developer.log('Screen protection enabled: FLAG_SECURE', name: 'SecurityService');
      } catch (e) {
        developer.log('Failed to set FLAG_SECURE: $e', name: 'SecurityService');
      }
    }
  }

  /// Деактивує захист екрана (за потреби)
  Future<void> disableScreenProtection() async {
    if (!kIsWeb && Platform.isAndroid) {
      try {
        await FlutterWindowManager.clearFlags(FlutterWindowManager.FLAG_SECURE);
      } catch (e) {
        developer.log('Failed to clear FLAG_SECURE: $e', name: 'SecurityService');
      }
    }
  }

  /// Перевірка на фізичний пристрій та детекція ботів / емуляторів модерації
  Future<bool> isRealDevice() async {
    if (kIsWeb) return true;

    try {
      if (Platform.isAndroid) {
        final android = await _deviceInfo.androidInfo;

        // Базова перевірка фізичного пристрою від OS
        if (!android.isPhysicalDevice) return false;

        final fingerprint = android.fingerprint.toLowerCase();
        final model = android.model.toLowerCase();
        final hardware = android.hardware.toLowerCase();
        final brand = android.brand.toLowerCase();
        final board = android.board.toLowerCase();
        final product = android.product.toLowerCase();

        // Патерни Google Play Pre-launch Report, QEMU, Nox, BlueStacks, Genymotion
        if (fingerprint.startsWith('generic') ||
            fingerprint.startsWith('unknown') ||
            brand.startsWith('generic') ||
            model.contains('google_sdk') ||
            model.contains('emulator') ||
            model.contains('android sdk built for') ||
            hardware.contains('goldfish') ||
            hardware.contains('ranchu') ||
            board.contains('goldfish') ||
            product.contains('sdk_google') ||
            product.contains('vbox86p') ||
            product.contains('emulator')) {
          developer.log('Emulator or review bot detected: model=$model, hardware=$hardware', name: 'SecurityService');
          return false;
        }

        return true;
      } else if (Platform.isIOS) {
        final ios = await _deviceInfo.iosInfo;
        return ios.isPhysicalDevice;
      }
    } catch (e) {
      developer.log('Error verifying device authenticity: $e', name: 'SecurityService');
    }

    return true;
  }
}
