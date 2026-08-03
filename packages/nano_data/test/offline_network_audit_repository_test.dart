import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake offline network audit repo returns offline pass', () async {
    final repo = FakeOfflineNetworkAuditRepository();
    final report = await repo.loadReport();
    expect(report.allPassed, isTrue);
    expect(report.quality, NetworkQuality.offline);
    expect(report.checks, isNotEmpty);
  });

  test('latencyMs overrides quality', () async {
    final repo = FakeOfflineNetworkAuditRepository();
    final report = await repo.loadReport(
      quality: NetworkQuality.ok,
      latencyMs: PoorNetworkBudgets.poorLatencyMs,
    );
    expect(report.quality, NetworkQuality.poor);
  });
}
