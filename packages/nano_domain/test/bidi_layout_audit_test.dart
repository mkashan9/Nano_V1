import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('Urdu smoke report passes at 360px and textScale 1.3', () {
    final report = BidiLayoutAuditPolicy.evaluate();
    expect(report.allPassed, isTrue);
    expect(report.locale, NanoAppLocale.ur);
    expect(report.checks.any((check) => check.id == 'bidi.direction'), isTrue);
  });

  test('Urdu locale is RTL and English is LTR', () {
    expect(NanoAppLocale.ur.isRtl, isTrue);
    expect(NanoAppLocale.en.isRtl, isFalse);
    final en = BidiLayoutAuditPolicy.evaluate(locale: NanoAppLocale.en);
    expect(en.allPassed, isTrue);
    expect(
      en.checks.firstWhere((check) => check.id == 'bidi.direction').detail,
      contains('LTR'),
    );
  });

  test('overflow fails Urdu smoke', () {
    final report = BidiLayoutAuditPolicy.evaluate(overflowDetected: true);
    expect(report.allPassed, isFalse);
    expect(
      report.checks.firstWhere((check) => check.id == 'bidi.overflow').status,
      BidiLayoutCheckStatus.fail,
    );
  });

  test('narrow width fails small-phone floor', () {
    final report = BidiLayoutAuditPolicy.evaluate(width: 320);
    expect(
      report.checks
          .firstWhere((check) => check.id == 'bidi.small_phone')
          .status,
      BidiLayoutCheckStatus.fail,
    );
  });
}
