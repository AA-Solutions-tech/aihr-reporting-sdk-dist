// `flutter_inappwebview`'s InAppWebView needs a real platform and cannot be
// mounted in a plain `flutter test`, so these tests cover the pure logic. The
// widget itself is verified on a device via the example app.
import 'package:aihr_reporting_sdk/aihr_reporting_sdk.dart';
import 'package:aihr_reporting_sdk/src/navigation_policy.dart';
import 'package:aihr_reporting_sdk/src/reporting_scripts.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('buildSetAuthTokenScript', () {
    test('embeds the token as an escaped JS string literal', () {
      expect(
        buildSetAuthTokenScript('abc.def.ghi'),
        'window.AIHR_REPORTING && window.AIHR_REPORTING.setAuthToken("abc.def.ghi");',
      );
    });

    test('cannot be broken out of with quotes, backslashes or script tags', () {
      expect(buildSetAuthTokenScript('a"b'), contains(r'a\"b'));
      expect(buildSetAuthTokenScript(r'a\b'), contains(r'a\\b'));
      expect(buildSetAuthTokenScript('");alert(1);//'), contains(r'\");alert(1);//'));
    });
  });

  group('buildSetLanguageScript', () {
    test('calls setLanguage with the language', () {
      expect(
        buildSetLanguageScript('ar'),
        'window.AIHR_REPORTING && window.AIHR_REPORTING.setLanguage("ar");',
      );
    });
  });

  group('normalizeLanguage', () {
    test('is Arabic only for "ar"', () {
      expect(normalizeLanguage('ar'), 'ar');
      expect(normalizeLanguage('en'), 'en');
      expect(normalizeLanguage('fr'), 'en');
      expect(normalizeLanguage(null), 'en');
    });
  });

  group('authErrorReason', () {
    test('reads a string reason and ignores anything else', () {
      expect(authErrorReason(['Session expired']), 'Session expired');
      expect(authErrorReason([]), isNull);
      expect(authErrorReason([null]), isNull);
      expect(authErrorReason([5]), isNull);
    });
  });

  group('isAllowedNavigation', () {
    final base = Uri.parse('https://hr.aasolutions.tech/HR/aihr-reporting-app/');

    test('allows the page itself and about:blank', () {
      expect(isAllowedNavigation(Uri.parse('https://hr.aasolutions.tech/HR/aihr-reporting-app/?lang=ar'), base), isTrue);
      expect(isAllowedNavigation(Uri.parse('about:blank'), base), isTrue);
    });

    test('blocks other hosts, schemes, ports and javascript: URLs', () {
      expect(isAllowedNavigation(Uri.parse('https://evil.example/'), base), isFalse);
      expect(isAllowedNavigation(Uri.parse('http://hr.aasolutions.tech/HR/aihr-reporting-app/'), base), isFalse);
      expect(isAllowedNavigation(Uri.parse('https://hr.aasolutions.tech:8443/'), base), isFalse);
      expect(isAllowedNavigation(Uri.parse('javascript:alert(1)'), base), isFalse);
      expect(isAllowedNavigation(Uri.parse('about:srcdoc'), base), isFalse);
      expect(isAllowedNavigation(null, base), isFalse);
    });
  });

  test('the public API exports the widget', () {
    const widget = AiHrReportingWidget(authToken: 'tok');
    expect(widget.authToken, 'tok');
    expect(widget.language, isNull);
  });
}
