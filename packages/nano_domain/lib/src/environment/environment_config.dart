import 'nano_environment.dart';
import 'service_endpoint.dart';

class EnvironmentConfig {
  const EnvironmentConfig({
    required this.environment,
    required this.supabaseUrl,
    required this.supabaseAnonKey,
    required this.featureFlags,
    this.appDisplayName = 'Nano',
  });

  final NanoEnvironment environment;
  final String supabaseUrl;
  final String supabaseAnonKey;
  final Map<String, bool> featureFlags;
  final String appDisplayName;

  ServiceEndpoint get supabaseEndpoint =>
      ServiceEndpoint(name: 'supabase', baseUrl: supabaseUrl);

  bool isFeatureEnabled(String flag) => featureFlags[flag] ?? false;

  factory EnvironmentConfig.fromEnvironment({
    String environmentName = const String.fromEnvironment(
      'NANO_ENV',
      defaultValue: 'development',
    ),
    String supabaseUrl = const String.fromEnvironment('SUPABASE_URL'),
    String supabaseAnonKey = const String.fromEnvironment('SUPABASE_ANON_KEY'),
  }) {
    final env = NanoEnvironment.fromName(environmentName);
    if (env.isProduction) {
      if (supabaseUrl.isEmpty || supabaseAnonKey.isEmpty) {
        throw StateError(
          'Production builds require SUPABASE_URL and SUPABASE_ANON_KEY.',
        );
      }
      if (supabaseAnonKey.contains('test') ||
          supabaseUrl.contains('localhost')) {
        throw StateError(
          'Production builds must not use test credentials or localhost endpoints.',
        );
      }
    }
    // QA-01: never allow service-role material in the Flutter anon slot.
    if (supabaseAnonKey.toLowerCase().contains('service_role')) {
      throw StateError(
        'SUPABASE_ANON_KEY must not contain service_role material.',
      );
    }
    return EnvironmentConfig(
      environment: env,
      supabaseUrl: supabaseUrl,
      supabaseAnonKey: supabaseAnonKey,
      featureFlags: const {'diagnostics': true, 'games_kill_switch': false},
    );
  }
}
