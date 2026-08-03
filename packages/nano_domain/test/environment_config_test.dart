import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('NanoEnvironment', () {
    test('parses known names', () {
      expect(NanoEnvironment.fromName('staging'), NanoEnvironment.staging);
      expect(
        NanoEnvironment.fromName('production'),
        NanoEnvironment.production,
      );
      expect(NanoEnvironment.fromName(null), NanoEnvironment.development);
    });

    test('debug tools hidden in production', () {
      expect(NanoEnvironment.production.showDebugTools, isFalse);
      expect(NanoEnvironment.development.showDebugTools, isTrue);
    });
  });

  group('EnvironmentConfig', () {
    test('exposes supabase endpoint', () {
      const config = EnvironmentConfig(
        environment: NanoEnvironment.development,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon',
        featureFlags: {'diagnostics': true},
      );
      expect(config.supabaseEndpoint.baseUrl, 'https://example.supabase.co');
      expect(config.isFeatureEnabled('diagnostics'), isTrue);
      expect(config.appDisplayName, 'Nano');
    });

    test('debug chrome is opt-in even in development', () {
      const plain = EnvironmentConfig(
        environment: NanoEnvironment.development,
        supabaseUrl: '',
        supabaseAnonKey: '',
        featureFlags: {'diagnostics': true},
      );
      expect(plain.showDebugChrome, isFalse);

      const enabled = EnvironmentConfig(
        environment: NanoEnvironment.development,
        supabaseUrl: '',
        supabaseAnonKey: '',
        featureFlags: {'debug_tools': true},
      );
      expect(enabled.showDebugChrome, isTrue);

      const production = EnvironmentConfig(
        environment: NanoEnvironment.production,
        supabaseUrl: 'https://example.supabase.co',
        supabaseAnonKey: 'anon',
        featureFlags: {'debug_tools': true},
      );
      expect(production.showDebugChrome, isFalse);
    });
  });
}
