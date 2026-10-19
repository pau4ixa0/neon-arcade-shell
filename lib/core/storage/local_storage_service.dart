import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class LocalStorageService {
  static const String _keyTargetOfferUrl = 'key_target_offer_url';
  static const String _keyWasOfferShown = 'key_was_offer_shown';
  static const String _keyIsFirstRun = 'key_is_first_run';
  static const String _keySubIds = 'key_sub_ids';
  static const String _keyPushToken = 'key_push_token';
  static const String _keyAppsFlyerId = 'key_appsflyer_id';

  static LocalStorageService? _instance;
  static SharedPreferences? _preferences;

  LocalStorageService._();

  static Future<LocalStorageService> getInstance() async {
    if (_instance == null) {
      _instance = LocalStorageService._();
      _preferences = await SharedPreferences.getInstance();
    }
    return _instance!;
  }

  // --- Target Offer URL ---

  String? getTargetOfferUrl() {
    return _preferences?.getString(_keyTargetOfferUrl);
  }

  Future<bool> setTargetOfferUrl(String url) async {
    return await _preferences?.setString(_keyTargetOfferUrl, url) ?? false;
  }

  Future<bool> removeTargetOfferUrl() async {
    return await _preferences?.remove(_keyTargetOfferUrl) ?? false;
  }

  // --- Was Offer Successfully Shown / Opened ---

  bool wasOfferShown() {
    return _preferences?.getBool(_keyWasOfferShown) ?? false;
  }

  Future<bool> setOfferShown(bool value) async {
    return await _preferences?.setBool(_keyWasOfferShown, value) ?? false;
  }

  // --- First Run State ---

  bool isFirstRun() {
    return _preferences?.getBool(_keyIsFirstRun) ?? true;
  }

  Future<bool> setFirstRunCompleted() async {
    return await _preferences?.setBool(_keyIsFirstRun, false) ?? false;
  }

  // --- Advertising Sub IDs ---

  Map<String, String> getSubIds() {
    final rawJson = _preferences?.getString(_keySubIds);
    if (rawJson == null || rawJson.isEmpty) return {};
    try {
      final decoded = jsonDecode(rawJson) as Map<String, dynamic>;
      return decoded.map((key, value) => MapEntry(key, value.toString()));
    } catch (_) {
      return {};
    }
  }

  Future<bool> saveSubIds(Map<String, String> subIds) async {
    final rawJson = jsonEncode(subIds);
    return await _preferences?.setString(_keySubIds, rawJson) ?? false;
  }

  String? getSubId(String key) {
    final subIds = getSubIds();
    return subIds[key];
  }

  Future<bool> setSubId(String key, String value) async {
    final currentSubIds = getSubIds();
    currentSubIds[key] = value;
    return await saveSubIds(currentSubIds);
  }

  // --- Push Token & Attribution Identifiers ---

  String? getPushToken() {
    return _preferences?.getString(_keyPushToken);
  }

  Future<bool> setPushToken(String token) async {
    return await _preferences?.setString(_keyPushToken, token) ?? false;
  }

  String? getAppsFlyerId() {
    return _preferences?.getString(_keyAppsFlyerId);
  }

  Future<bool> setAppsFlyerId(String id) async {
    return await _preferences?.setString(_keyAppsFlyerId, id) ?? false;
  }

  // --- Reset / Clear ---

  Future<bool> clearAll() async {
    return await _preferences?.clear() ?? false;
  }
}
