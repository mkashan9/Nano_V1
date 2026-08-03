import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake pilot release repo returns ready pass', () async {
    final repo = FakePilotReleaseRepository();
    final report = await repo.loadReport(
      config: const EnvironmentConfig(
        environment: NanoEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'public-anon-preview-key',
        featureFlags: {},
      ),
    );
    expect(report.allPassed, isTrue);
    expect(report.checks, isNotEmpty);
  });
}
