import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../core/analytics/analytics_service.dart';

class MainWebViewScreen extends StatefulWidget {
  final String initialUrl;
  final AnalyticsService analyticsService;

  const MainWebViewScreen({
    super.key,
    required this.initialUrl,
    required this.analyticsService,
  });

  @override
  State<MainWebViewScreen> createState() => _MainWebViewScreenState();
}

class _MainWebViewScreenState extends State<MainWebViewScreen> {
  InAppWebViewController? _webViewController;
  PullToRefreshController? _pullToRefreshController;
  double _progress = 0;
  bool _hasError = false;
  String _errorMessage = '';

  late InAppWebViewSettings _settings;

  @override
  void initState() {
    super.initState();

    _settings = InAppWebViewSettings(
      isInspectable: kDebugMode,
      javaScriptEnabled: true,
      javaScriptCanOpenWindowsAutomatically: true,
      domStorageEnabled: true,
      databaseEnabled: true,
      cacheEnabled: true,
      clearCache: false,
      allowsInlineMediaPlayback: true,
      useHybridComposition: true,
      transparentBackground: false,
      supportMultipleWindows: true,
      useOnDownloadStart: true,
      allowFileAccessFromFileURLs: true,
      allowUniversalAccessFromFileURLs: true,
      mediaPlaybackRequiresUserGesture: false,
      geolocationEnabled: true,
    );

    _pullToRefreshController = kIsWeb
        ? null
        : PullToRefreshController(
            settings: PullToRefreshSettings(
              color: Colors.amberAccent,
            ),
            onRefresh: () async {
              if (defaultTargetPlatform == TargetPlatform.android) {
                _webViewController?.reload();
              } else if (defaultTargetPlatform == TargetPlatform.iOS) {
                _webViewController?.loadUrl(
                  urlRequest: URLRequest(url: await _webViewController?.getUrl()),
                );
              }
            },
          );
  }

  /// Обробка дозволів на камеру та мікрофон для верифікації документів KYC
  Future<PermissionResponse?> _handlePermissionRequest(
    InAppWebViewController controller,
    PermissionRequest request,
  ) async {
    return PermissionResponse(
      resources: request.resources,
      action: PermissionResponseAction.GRANT,
    );
  }

  /// Обробка геолокаційних запитів від гемблінг-платформи
  Future<GeolocationPermissionShowPromptResponse> _handleGeolocationPrompt(
    InAppWebViewController controller,
    String origin,
  ) async {
    final status = await Permission.locationWhenInUse.request();
    return GeolocationPermissionShowPromptResponse(
      origin: origin,
      allow: status.isGranted,
      retain: true,
    );
  }

  /// Перехоплення зовнішніх протоколів (tg://, whatsapp://, viber://, tel:, mailto:)
  Future<NavigationActionPolicy> _handleNavigationPolicy(
    InAppWebViewController controller,
    NavigationAction navigationAction,
  ) async {
    final uri = navigationAction.request.url;
    if (uri == null) return NavigationActionPolicy.ALLOW;

    final scheme = uri.scheme.toLowerCase();
    if (scheme != 'http' && scheme != 'https') {
      try {
        if (await canLaunchUrl(uri)) {
          await launchUrl(uri, mode: LaunchMode.externalApplication);
          return NavigationActionPolicy.CANCEL;
        }
      } catch (e) {
        developer.log('External scheme launch error: $uri', error: e);
      }
      return NavigationActionPolicy.CANCEL;
    }

    return NavigationActionPolicy.ALLOW;
  }

  /// Реєстрація JavaScript Bridge для передачі подій з веб-сайту казино в AppsFlyer
  void _registerJavaScriptHandlers(InAppWebViewController controller) {
    // 1. Реєстрація гравця: window.flutter_inappwebview.callHandler('trackRegistration', 'user_12345')
    controller.addJavaScriptHandler(
      handlerName: 'trackRegistration',
      callback: (args) {
        final userId = args.isNotEmpty ? args[0]?.toString() : null;
        widget.analyticsService.trackRegistration(userId: userId);
      },
    );

    // 2. Депозит гравця: window.flutter_inappwebview.callHandler('trackDeposit', 50.0, 'USD', true)
    controller.addJavaScriptHandler(
      handlerName: 'trackDeposit',
      callback: (args) {
        if (args.isNotEmpty) {
          final double amount = double.tryParse(args[0]?.toString() ?? '0') ?? 0.0;
          final String currency = args.length > 1 ? args[1]?.toString() ?? 'USD' : 'USD';
          final bool isFirst = args.length > 2 ? (args[2] == true || args[2] == 'true') : false;

          widget.analyticsService.trackDeposit(
            amount: amount,
            currency: currency,
            isFirstDeposit: isFirst,
          );
        }
      },
    );

    // 3. Універсальна подія: window.flutter_inappwebview.callHandler('trackEvent', 'slot_spin', { bet: 2 })
    controller.addJavaScriptHandler(
      handlerName: 'trackEvent',
      callback: (args) {
        if (args.isNotEmpty) {
          final String eventName = args[0]?.toString() ?? 'custom_event';
          final Map<String, dynamic>? data = args.length > 1 && args[1] is Map
              ? Map<String, dynamic>.from(args[1] as Map)
              : null;
          widget.analyticsService.trackEvent(eventName, data);
        }
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        // Обробка апаратної кнопки "Назад" усередині історії WebView
        if (_webViewController != null && await _webViewController!.canGoBack()) {
          await _webViewController!.goBack();
        }
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        body: SafeArea(
          child: Stack(
            children: [
              if (!_hasError)
                InAppWebView(
                  initialUrlRequest: URLRequest(url: WebUri(widget.initialUrl)),
                  initialSettings: _settings,
                  pullToRefreshController: _pullToRefreshController,
                  onWebViewCreated: (controller) {
                    _webViewController = controller;
                    _registerJavaScriptHandlers(controller);
                  },
                  shouldOverrideUrlLoading: _handleNavigationPolicy,
                  onPermissionRequest: _handlePermissionRequest,
                  onGeolocationPermissionsShowPrompt: _handleGeolocationPrompt,
                  onLoadStart: (controller, url) {
                    setState(() {
                      _hasError = false;
                    });
                  },
                  onLoadStop: (controller, url) async {
                    _pullToRefreshController?.endRefreshing();
                    setState(() {
                      _progress = 1.0;
                    });
                  },
                  onProgressChanged: (controller, progress) {
                    if (progress == 100) {
                      _pullToRefreshController?.endRefreshing();
                    }
                    setState(() {
                      _progress = progress / 100.0;
                    });
                  },
                  onReceivedError: (controller, request, error) {
                    _pullToRefreshController?.endRefreshing();
                    if (request.isForMainFrame ?? true) {
                      setState(() {
                        _hasError = true;
                        _errorMessage = error.description;
                      });
                    }
                  },
                ),

              // Прогрес-бар завантаження
              if (_progress < 1.0 && !_hasError)
                LinearProgressIndicator(
                  value: _progress,
                  backgroundColor: Colors.transparent,
                  valueColor: const AlwaysStoppedAnimation<Color>(Colors.amberAccent),
                  minHeight: 2.5,
                ),

              // Екран помилки із кнопкою перезавантаження
              if (_hasError)
                Center(
                  child: Container(
                    margin: const EdgeInsets.all(24),
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E2E),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.wifi_off_rounded, color: Colors.amberAccent, size: 48),
                        const SizedBox(height: 16),
                        const Text(
                          'Connection Error',
                          style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _errorMessage.isNotEmpty ? _errorMessage : 'Unable to connect to the server.',
                          textAlign: TextAlign.center,
                          style: const TextStyle(color: Colors.white70, fontSize: 14),
                        ),
                        const SizedBox(height: 20),
                        ElevatedButton.icon(
                          onPressed: () {
                            setState(() {
                              _hasError = false;
                            });
                            _webViewController?.reload();
                          },
                          icon: const Icon(Icons.refresh, color: Colors.black),
                          label: const Text('Try Again', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.amberAccent,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
