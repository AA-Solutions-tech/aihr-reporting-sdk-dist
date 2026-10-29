import 'package:flutter/widgets.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';

import 'navigation_policy.dart';
import 'reporting_scripts.dart';

/// Where the always-current build of the reporting chat page is hosted.
/// Changing the page or the reporting agent reaches every installed app on the
/// next backend deploy, with no app release. Override for local development
/// with `--dart-define=AIHR_REPORTING_BASE_URL=...`.
const String _kBaseUrl = String.fromEnvironment(
  'AIHR_REPORTING_BASE_URL',
  defaultValue: 'https://hr.aasolutions.tech/HR/aihr-reporting-app/',
);

/// The NizamyAI reporting chat.
///
/// Pass the owner's current access token in [authToken]. The chat itself is
/// held in the page's memory only: nothing is stored on the phone or on our
/// servers, and it is gone when this widget is closed.
///
/// ```dart
/// AiHrReportingWidget(
///   authToken: accessToken,
///   onAuthError: (reason) async => setState(() => accessToken = await refresh()),
///   onClose: () => Navigator.of(context).pop(),
/// )
/// ```
class AiHrReportingWidget extends StatefulWidget {
  const AiHrReportingWidget({
    super.key,
    required this.authToken,
    this.language,
    this.onAuthError,
    this.onClose,
  });

  /// The owner's current access token. Held in memory by the page only; it is
  /// never written to disk or put in a URL. Rebuild the widget with a new token
  /// after a refresh and the page picks it up without reloading.
  final String authToken;

  /// Explicit language override ('en' or 'ar'). Leave null to follow the
  /// ambient `Localizations.localeOf(context)`.
  final String? language;

  /// Called when the backend rejects the token. Refresh it and rebuild this
  /// widget with the new [authToken]; the conversation is kept.
  final void Function(String? reason)? onAuthError;

  /// Called when the user taps back in the chat header.
  final VoidCallback? onClose;

  @override
  State<AiHrReportingWidget> createState() => _AiHrReportingWidgetState();
}

class _AiHrReportingWidgetState extends State<AiHrReportingWidget> {
  final Uri _base = Uri.parse(_kBaseUrl);
  InAppWebViewController? _controller;
  String _language = 'en';
  bool _loadFailed = false;

  String _resolveLanguage() =>
      normalizeLanguage(widget.language ?? Localizations.localeOf(context).languageCode);

  Uri get _initialUrl => _base.replace(queryParameters: {'lang': _language});

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _syncLanguage();
  }

  @override
  void didUpdateWidget(covariant AiHrReportingWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.authToken != oldWidget.authToken) {
      _inject(buildSetAuthTokenScript(widget.authToken));
    }
    _syncLanguage();
  }

  void _syncLanguage() {
    final resolved = _resolveLanguage();
    if (resolved != _language) {
      _language = resolved;
      _inject(buildSetLanguageScript(resolved));
    }
  }

  Future<void> _inject(String script) async {
    final controller = _controller;
    if (controller == null) return;
    await controller.evaluateJavascript(source: script);
  }

  void _retry() {
    setState(() => _loadFailed = false);
    _controller?.loadUrl(urlRequest: URLRequest(url: WebUri.uri(_initialUrl)));
  }

  @override
  Widget build(BuildContext context) {
    if (_loadFailed) {
      return _LoadErrorView(language: _language, onRetry: _retry);
    }
    return InAppWebView(
      initialUrlRequest: URLRequest(url: WebUri.uri(_initialUrl)),
      initialSettings: InAppWebViewSettings(
        javaScriptEnabled: true,
        useShouldOverrideUrlLoading: true,
        javaScriptCanOpenWindowsAutomatically: false,
        supportMultipleWindows: false,
        allowFileAccess: false,
        allowContentAccess: false,
        cacheEnabled: false,
        incognito: true,
      ),
      shouldOverrideUrlLoading: (controller, action) async {
        final allowed = isAllowedNavigation(action.request.url?.uriValue, _base);
        return allowed ? NavigationActionPolicy.ALLOW : NavigationActionPolicy.CANCEL;
      },
      onWebViewCreated: (controller) {
        _controller = controller;
        controller.addJavaScriptHandler(
          handlerName: 'onAuthError',
          callback: (args) => widget.onAuthError?.call(authErrorReason(args)),
        );
        controller.addJavaScriptHandler(
          handlerName: 'onClose',
          callback: (args) => widget.onClose?.call(),
        );
      },
      onConsoleMessage: (controller, message) {
        debugPrint('[aihr_reporting_sdk console] $message');
      },
      onReceivedError: (controller, request, error) {
        if (request.isForMainFrame ?? true) setState(() => _loadFailed = true);
      },
      onReceivedHttpError: (controller, request, response) {
        if (request.isForMainFrame ?? true) setState(() => _loadFailed = true);
      },
      onLoadStop: (controller, url) async {
        await _inject(buildSetAuthTokenScript(widget.authToken));
        await _inject(buildSetLanguageScript(_language));
      },
    );
  }
}

class _LoadErrorView extends StatelessWidget {
  const _LoadErrorView({required this.language, required this.onRetry});

  final String language;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isArabic = language == 'ar';
    return Directionality(
      textDirection: isArabic ? TextDirection.rtl : TextDirection.ltr,
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isArabic
                    ? 'تعذّر تحميل التقارير. تحقق من الاتصال.'
                    : 'Could not load reporting. Check your connection.',
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 14, color: Color(0xFF4E4E4E)),
              ),
              const SizedBox(height: 12),
              GestureDetector(
                onTap: onRetry,
                child: Text(
                  isArabic ? 'إعادة المحاولة' : 'Retry',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0192E1),
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
