import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  const safeConfig = EnvironmentConfig(
    environment: NanoEnvironment.development,
    supabaseUrl: 'https://example.supabase.co',
    supabaseAnonKey: 'public-anon-preview-key',
    featureFlags: {},
  );

  test('secret pattern policy flags service role and key files', () {
    expect(
      SecretPatternPolicy.findLeaks('service_role jwt here'),
      isNotEmpty,
    );
    expect(SecretPatternPolicy.findLeaks('api_s.txt'), isNotEmpty);
    expect(SecretPatternPolicy.findLeaks('harmless anon text'), isEmpty);
  });

  test('client config hardening fails on service_role anon slot', () {
    final bad = ClientConfigHardening.evaluate(
      const EnvironmentConfig(
        environment: NanoEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'service_role-should-fail',
        featureFlags: {},
      ),
    );
    expect(bad.status, SecurityCheckStatus.fail);

    final good = ClientConfigHardening.evaluate(safeConfig);
    expect(good.status, SecurityCheckStatus.pass);
  });

  test('access guard hardening requires expected denials', () {
    expect(AccessGuardHardening.evaluate().passed, isTrue);
  });

  test('full report passes for safe preview config', () {
    final report = SecurityHardeningPolicy.evaluate(config: safeConfig);
    expect(report.allPassed, isTrue);
    expect(report.checks, isNotEmpty);
  });

  test('fromEnvironment rejects service_role anon keys', () {
    expect(
      () => EnvironmentConfig.fromEnvironment(
        environmentName: 'development',
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'eyJservice_role',
      ),
      throwsStateError,
    );
  });
}
