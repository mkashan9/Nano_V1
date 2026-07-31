import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Reads and writes personal learner settings.
abstract class StudentPreferencesRepository {
  Future<StudentPreferences> load(String userId);

  Future<StudentPreferences> save(StudentPreferences preferences);
}

/// In-memory settings for widget tests and UI-first development.
class FakeStudentPreferencesRepository implements StudentPreferencesRepository {
  FakeStudentPreferencesRepository({this.seed});

  final StudentPreferences? seed;
  final Map<String, StudentPreferences> _rows = {};
  final List<StudentPreferences> writes = [];

  @override
  Future<StudentPreferences> load(String userId) async {
    return _rows[userId] ??
        (seed?.userId == userId ? seed! : StudentPreferences(userId: userId));
  }

  @override
  Future<StudentPreferences> save(StudentPreferences preferences) async {
    final error = CompanionNamePolicy.validate(preferences.companionName);
    if (error != null) {
      throw ArgumentError(error);
    }
    final normalized = preferences.copyWith(
      companionName: CompanionNamePolicy.normalize(preferences.companionName),
    );
    _rows[normalized.userId] = normalized;
    writes.add(normalized);
    return normalized;
  }
}

/// Supabase-backed settings. RLS keeps every row private to its owner.
class SupabaseStudentPreferencesRepository
    implements StudentPreferencesRepository {
  SupabaseStudentPreferencesRepository(this.client);

  final SupabaseClient client;

  static const _table = 'student_preferences';
  static const _columns = 'user_id, companion_name, locale, sound_enabled, '
      'haptics_enabled, captions_enabled, reduced_motion, classroom_mode, '
      'text_scale';

  @override
  Future<StudentPreferences> load(String userId) async {
    final rows =
        await client.from(_table).select(_columns).eq('user_id', userId).limit(1);
    if (rows.isEmpty) {
      return StudentPreferences(userId: userId);
    }
    return StudentPreferences.fromRow(Map<String, dynamic>.from(rows.first));
  }

  @override
  Future<StudentPreferences> save(StudentPreferences preferences) async {
    final error = CompanionNamePolicy.validate(preferences.companionName);
    if (error != null) {
      throw ArgumentError(error);
    }
    final rows = await client
        .from(_table)
        .upsert(preferences.toRow(), onConflict: 'user_id')
        .select(_columns);
    if (rows.isEmpty) return preferences;
    return StudentPreferences.fromRow(Map<String, dynamic>.from(rows.first));
  }
}
