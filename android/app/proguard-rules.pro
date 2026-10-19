# Flutter Wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.**  { *; }
-keep class io.flutter.util.**  { *; }
-keep class io.flutter.view.**  { *; }
-keep class io.flutter.**  { *; }
-keep class io.flutter.plugins.**  { *; }

# Preserve JavaScript Interface for Web ↔ Native Bridge
-keepattributes JavascriptInterface
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}

# Flutter InAppWebView rules
-keep class com.pichillilorenzo.flutter_inappwebview_android.** { *; }
-dontwarn com.pichillilorenzo.flutter_inappwebview_android.**

# AppsFlyer SDK rules
-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**

# Firebase Core, FCM & Remote Config rules
-keep class com.google.firebase.** { *; }
-dontwarn com.google.firebase.**

# SharedPreferences & Local Notifications
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-dontwarn com.dexterous.flutterlocalnotifications.**
