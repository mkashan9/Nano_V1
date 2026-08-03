import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake repo returns a passing hardening report', () async {
    final repo = FakeSecurityHardeningRepository();
    final report = await repo.loadReport(
      config: const EnvironmentConfig(
        environment: NanoEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'public-anon-preview-key',
        featureFlags: {},
      ),
      principal: SessionPrincipal.superadmin(),
    );
    expect(report.allPassed, isTrue);
    expect(
      report.checks.any((check) => check.id == 'access.guard'),
      isTrue,
    );
  });
}
