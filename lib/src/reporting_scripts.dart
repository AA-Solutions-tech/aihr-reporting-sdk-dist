import 'dart:convert';

/// Builds the JavaScript that hands the access token to the reporting page.
///
/// A pure function (no widget or platform dependency) so it can be unit
/// tested. `jsonEncode` produces a correctly escaped JavaScript string
/// literal, so the token can never break out of the call.
String buildSetAuthTokenScript(String token) =>
    'window.AIHR_REPORTING && window.AIHR_REPORTING.setAuthToken(${jsonEncode(token)});';

/// Builds the JavaScript that hands the host app's language ('en' or 'ar')
/// to the reporting page.
String buildSetLanguageScript(String language) =>
    'window.AIHR_REPORTING && window.AIHR_REPORTING.setLanguage(${jsonEncode(language)});';

/// 'ar' only for an explicit Arabic code; everything else is English.
String normalizeLanguage(String? raw) => raw == 'ar' ? 'ar' : 'en';

/// Reads the reason the page passed to `onAuthError`; null when it is not a string.
String? authErrorReason(List<dynamic> args) =>
    args.isNotEmpty && args.first is String ? args.first as String : null;
