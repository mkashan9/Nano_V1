import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake bidi layout audit repo returns Urdu smoke pass', () async {
    final repo = FakeBidiLayoutAuditRepository();
    final report = await repo.loadReport();
    expect(report.allPassed, isTrue);
    expect(report.locale, NanoAppLocale.ur);
    expect(report.checks, isNotEmpty);
  });
}
