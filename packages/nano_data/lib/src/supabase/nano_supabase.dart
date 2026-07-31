import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Thin gateway around Supabase. Never accepts or stores the service-role key.
class NanoSupabase {
  NanoSupabase(this.client);

  final SupabaseClient client;

  factory NanoSupabase.fromConfig(EnvironmentConfig config) {
    if (config.supabaseUrl.isEmpty || config.supabaseAnonKey.isEmpty) {
      throw StateError(
        'SUPABASE_URL and SUPABASE_ANON_KEY are required to open NanoSupabase.',
      );
    }
    return NanoSupabase(
      SupabaseClient(config.supabaseUrl, config.supabaseAnonKey),
    );
  }

  /// Reads the SEC-01 health probe row.
  Future<AppHealthSnapshot?> fetchAppHealth() async {
    final rows = await client.from('app_health').select().eq('id', 'default');
    if (rows.isEmpty) return null;
    final row = rows.first;
    return AppHealthSnapshot(
      environment: row['environment'] as String? ?? 'unknown',
      schemaVersion: row['schema_version'] as String? ?? 'unknown',
      notes: row['notes'] as String? ?? '',
      updatedAt: DateTime.tryParse(row['updated_at'] as String? ?? ''),
    );
  }
}

class AppHealthSnapshot {
  const AppHealthSnapshot({
    required this.environment,
    required this.schemaVersion,
    required this.notes,
    this.updatedAt,
  });

  final String environment;
  final String schemaVersion;
  final String notes;
  final DateTime? updatedAt;
}
