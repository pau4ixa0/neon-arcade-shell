# Cross-Platform iGaming Traffic Shell (Flutter + Remote Config + AppsFlyer + FCM)

Повноцінний виробничий каркас мобільного додатка-оболонки (WebView Shell) для арбітражу трафіку на iGaming (гемблінг / беттінг). Додаток замаскований під казуальну гру (`Neon Tap Arcade`), має вбудовану систему захисту від ботів модерації (Cloaking / Anti-Emulator), підтримує пуш-сповіщення через Firebase Cloud Messaging (FCM) та повну передачу атрибуції (`sub_id`, `appsflyer_id`, `push_token`).

---

## 🏗️ Структура проєкту

```
lib/
├── main.dart                                   # Точка входу, FCM Background Handler, Screenshot Protection
├── core/
│   ├── constants/
│   │   └── app_constants.dart                 # Ключі Remote Config, сховища та AppsFlyer
│   ├── storage/
│   │   └── local_storage_service.dart         # Кешування цільового URL оферу (SharedPreferences)
│   ├── config/
│   │   └── remote_config_service.dart         # Firebase Remote Config, перевірка інтернет-з'єднання
│   ├── analytics/
│   │   └── analytics_service.dart             # AppsFlyer SDK: Conversion Data, Sub1-Sub10, iGaming події
│   ├── notifications/
│   │   └── push_notification_service.dart     # FCM: отримання токена, підписка на топіки, показ сповіщень
│   └── security/
│       └── security_service.dart              # Anti-emulator (боти модерації) + заборона скріншотів (FLAG_SECURE)
└── features/
    ├── splash/
    │   └── presentation/
    │       └── splash_screen.dart             # Cloaking Gatekeeper / Traffic Router
    ├── webview/
    │   └── presentation/
    │       └── webview_screen.dart            # InAppWebView: JS Bridge, Geolocation, KYC Camera, Back Button
    └── fallback_game/
        └── presentation/
            └── game_screen.dart               # Легітимна казуальна міні-гра (Whitepage) для модераторів
```

---

## 🔒 Логіка Маскування (Cloaking & Review Protection)

Під час запуску додаток проходить ланцюжок фільтрації ([`SplashScreen`](file:///e:/BetWinner_apps/lib/features/splash/presentation/splash_screen.dart)):

1. **Saved State Check:** Якщо користувач уже є верифікованим реальним гравцем (офер відкривався раніше) — миттєвий перехід на збережений URL.
2. **Anti-Bot / Anti-Emulator Check:** Автоматичні робочі боти Google Play Pre-launch Report та емулятори Apple / TestStudio блокуються на рівні аналізу відбитків обладнання (`fingerprint`, `qemu`, `goldfish`, `generic x86`). Вони спрямовуються на **Whitepage** (гру).
3. **Network Check:** Перевірка реального пінгу до DNS. Якщо офлайн — запуск гри.
4. **Remote Config Gatekeeper:**
   - Якщо параметр `is_cloaking_active == false` (етап рев'ю в Google/Apple) — всі користувачі бачать гру.
   - Якщо параметр `is_cloaking_active == true` та вказано `target_offer_url` — формується результуючий URL оферу з передачею трекінг-параметрів.

---

## 📊 Формування результуючого URL оферу

[`AnalyticsService.buildEnrichedUrl()`](file:///e:/BetWinner_apps/lib/core/analytics/analytics_service.dart#L56-L101) автоматично підставляє параметри в URL оферу:

```
https://your-casino-offer.com/landing?
  appsflyer_id=16977456789-1234567
  &push_token=fcm_device_token_xyz
  &campaign=fb_tier1_gambling_cpa
  &media_source=Facebook_Ads
  &sub1=fb_adset_id
  &sub2=fb_ad_id
  &sub3=target_geo
  &sub4=creative_id
```

Ці параметри дозволяють бекенду партнерської мережі прив'язати гравця до конкретного баєра та надсилати персональні тригерні push-сповіщення (наприклад, бонуси за депозит).

---

## 🌉 JavaScript Bridge (Web ↔ Native)

Сторінка оферу може надсилати події безпосередньо в нативний SDK додатку через об'єкт `window.flutter_inappwebview`:

```javascript
// 1. Реєстрація гравця
window.flutter_inappwebview.callHandler('trackRegistration', 'user_id_98765');

// 2. Депозит гравця
window.flutter_inappwebview.callHandler('trackDeposit', 50.0, 'USD', true); // amount, currency, isFirstDeposit

// 3. Довільна кастомна подія
window.flutter_inappwebview.callHandler('trackEvent', 'slot_spin', { bet: 2.5, game: 'Sweet Bonanza' });
```

---

## ⚙️ Налаштування платформ

### 1. Android (`android/app/src/main/AndroidManifest.xml`)

```xml
<manifest xmlns:android="http://schemas.android.com/apk/res/android">
    <uses-permission android:name="android.permission.INTERNET"/>
    <uses-permission android:name="android.permission.ACCESS_NETWORK_STATE"/>
    <uses-permission android:name="android.permission.POST_NOTIFICATIONS"/>
    <uses-permission android:name="android.permission.ACCESS_FINE_LOCATION"/>
    <uses-permission android:name="android.permission.ACCESS_COARSE_LOCATION"/>
    <uses-permission android:name="android.permission.CAMERA"/>
    <uses-permission android:name="com.google.android.gms.permission.AD_ID"/>

    <!-- Дозволи для відкриття сторонніх сервісів, банків та месенджерів -->
    <queries>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="https" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="tg" />
        </intent>
        <intent>
            <action android:name="android.intent.action.VIEW" />
            <data android:scheme="whatsapp" />
        </intent>
    </queries>

    <application
        android:label="Arcade Challenge"
        android:hardwareAccelerated="true"
        android:usesCleartextTraffic="true">
        
        <!-- Іконка сповіщень за замовчуванням -->
        <meta-data
            android:name="com.google.firebase.messaging.default_notification_icon"
            android:resource="@mipmap/ic_launcher" />
    </application>
</manifest>
```

### 2. iOS (`ios/Runner/Info.plist`)

```xml
<key>NSUserTrackingUsageDescription</key>
<string>We need this identifier to provide personalized gameplay experiences and bonuses.</string>
<key>NSCameraUsageDescription</key>
<string>Camera access is required for document verification during identity check.</string>
<key>NSLocationWhenInUseUsageDescription</key>
<string>Location access is needed to ensure services comply with local gaming regulations.</string>
<key>UIBackgroundModes</key>
<array>
    <string>fetch</string>
    <string>remote-notification</string>
</array>
<key>NSAppTransportSecurity</key>
<dict>
    <key>NSAllowsArbitraryLoads</key>
    <true/>
</dict>
```

---

## 🚀 Інструкція із запуску збірки

1. **Встановлення залежностей:**
   ```bash
   flutter pub get
   ```
2. **Конфігурація ключів:**
   - У [app_constants.dart](file:///e:/BetWinner_apps/lib/core/constants/app_constants.dart) вкажіть ваш `appsFlyerDevKey` та `appsFlyerAppIdIos`.
3. **Файли Firebase:**
   - Покладіть `google-services.json` у `android/app/`
   - Покладіть `GoogleService-Info.plist` у `ios/Runner/`
4. **Збірка релізних версій:**
   - **Google Play:** `flutter build appbundle --release`
   - **App Store:** `flutter build ipa --release`
