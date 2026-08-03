import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake performance audit repo returns small-phone smoke pass', () async {
    final repo = FakePerformanceAuditRepository();
    final report = await repo.loadReport();
    expect(report.allPassed, isTrue);
    expect(report.checks, isNotEmpty);
  });
}
