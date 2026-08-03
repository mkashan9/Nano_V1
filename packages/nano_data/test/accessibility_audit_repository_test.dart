import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake accessibility audit repo returns smoke pass', () async {
    final repo = FakeAccessibilityAuditRepository();
    final report = await repo.loadReport();
    expect(report.allPassed, isTrue);
    expect(report.checks, isNotEmpty);
  });
}
