import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('pilot-ready gates all pass in development', () {
    final report = PilotReleasePolicy.evaluate(
      config: const EnvironmentConfig(
        environment: NanoEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'public-anon-preview-key',
        featureFlags: {},
      ),
    );
    expect(report.allPassed, isTrue);
    expect(report.checks.any((check) => check.id == 'pilot.qa01'), isTrue);
    expect(report.checks.any((check) => check.id == 'pilot.qa05'), isTrue);
  });

  test('missing QA gate fails readiness', () {
    final report = PilotReleasePolicy.evaluate(
      gates: const PilotReleaseGates(qa03Offline: false),
    );
    expect(report.allPassed, isFalse);
    expect(
      report.checks.firstWhere((check) => check.id == 'pilot.qa03').status,
      PilotReleaseCheckStatus.fail,
    );
  });

  test('production environment warns', () {
    final report = PilotReleasePolicy.evaluate(
      config: const EnvironmentConfig(
        environment: NanoEnvironment.production,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'public-anon-preview-key',
        featureFlags: {},
      ),
    );
    expect(report.allPassed, isTrue);
    expect(
      report.checks.firstWhere((check) => check.id == 'pilot.environment').status,
      PilotReleaseCheckStatus.warn,
    );
  });
}
