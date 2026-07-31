import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Reads and writes first-run progress. UI depends on this, not on Supabase.
abstract class OnboardingRepository {
  Future<OnboardingProgress> load(String userId);

  Future<OnboardingProgress> save(OnboardingProgress progress);
}

/// In-memory repository for widget tests and UI-first development.
class FakeOnboardingRepository implements OnboardingRepository {
  FakeOnboardingRepository({this.seed});

  final OnboardingProgress? seed;
  final Map<String, OnboardingProgress> _rows = {};
  final List<OnboardingProgress> writes = [];

  @override
  Future<OnboardingProgress> load(String userId) async {
    return _rows[userId] ??
        (seed?.userId == userId ? seed! : OnboardingProgress(userId: userId));
  }

  @override
  Future<OnboardingProgress> save(OnboardingProgress progress) async {
    _rows[progress.userId] = progress;
    writes.add(progress);
    return progress;
  }
}

/// Supabase-backed progress. RLS restricts every row to its owner.
class SupabaseOnboardingRepository implements OnboardingRepository {
  SupabaseOnboardingRepository(this.client);

  final SupabaseClient client;

  static const _table = 'student_onboarding';

  @override
  Future<OnboardingProgress> load(String userId) async {
    final rows = await client
        .from(_table)
        .select('user_id, current_step, self_reported_grade_level, '
            'experience_track, completed_at')
        .eq('user_id', userId)
        .limit(1);
    if (rows.isEmpty) {
      return OnboardingProgress(userId: userId);
    }
    return OnboardingProgress.fromRow(Map<String, dynamic>.from(rows.first));
  }

  @override
  Future<OnboardingProgress> save(OnboardingProgress progress) async {
    final rows = await client
        .from(_table)
        .upsert(progress.toRow(), onConflict: 'user_id')
        .select();
    if (rows.isEmpty) return progress;
    return OnboardingProgress.fromRow(Map<String, dynamic>.from(rows.first));
  }
}
