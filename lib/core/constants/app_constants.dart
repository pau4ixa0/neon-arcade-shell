class AppConstants {
  // Remote Config Keys
  static const String remoteConfigUrlKey = 'target_offer_url';
  static const String remoteConfigEnabledKey = 'is_cloaking_active';
  static const String remoteConfigAllowedGeosKey = 'allowed_geos';

  // Local Storage Keys
  static const String savedTargetUrlKey = 'saved_target_offer_url';
  static const String isFirstRunKey = 'is_first_run';
  static const String wasOfferShownKey = 'was_offer_shown';

  // AppsFlyer Configuration
  static const String appsFlyerDevKey = 'YOUR_APPSFLYER_DEV_KEY';
  static const String appsFlyerAppIdIos = 'YOUR_APPLE_APP_ID';

  // Timeouts & Network
  static const int networkTimeoutSeconds = 7;
}
