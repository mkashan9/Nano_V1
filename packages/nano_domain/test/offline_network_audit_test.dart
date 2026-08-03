import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('offline report passes with default trusted/draft policy', () {
    final report = OfflineNetworkAuditPolicy.evaluate();
    expect(report.allPassed, isTrue);
    expect(report.quality, NetworkQuality.offline);
    expect(
      report.checks.any((check) => check.id == 'offline.trusted_blocked'),
      isTrue,
    );
  });

  test('missing cache fails when offline', () {
    final report = OfflineNetworkAuditPolicy.evaluate(cacheHit: false);
    expect(report.allPassed, isFalse);
    expect(
      report.checks
          .firstWhere((check) => check.id == 'offline.cache_read')
          .status,
      OfflineNetworkCheckStatus.fail,
    );
  });

  test('latency maps to network quality', () {
    expect(NetworkQualityPolicy.fromLatencyMs(null), NetworkQuality.offline);
    expect(
      NetworkQualityPolicy.fromLatencyMs(PoorNetworkBudgets.poorLatencyMs),
      NetworkQuality.poor,
    );
    expect(NetworkQualityPolicy.fromLatencyMs(500), NetworkQuality.ok);
  });

  test('poor network keeps retry check passing', () {
    final report = OfflineNetworkAuditPolicy.evaluate(
      quality: NetworkQuality.poor,
    );
    expect(report.allPassed, isTrue);
    expect(
      report.checks.firstWhere((check) => check.id == 'offline.poor_retry').detail,
      contains('≥2s'),
    );
  });
}
