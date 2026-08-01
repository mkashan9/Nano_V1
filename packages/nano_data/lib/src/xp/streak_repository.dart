import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// XP-05 streak read side.
abstract class StreakRepository {
  Future<StreakSnapshot> current();
}

class FakeStreakRepository implements StreakRepository {
  FakeStreakRepository({this.snapshot = StreakSnapshot.empty});

  StreakSnapshot snapshot;

  @override
  Future<StreakSnapshot> current() async => snapshot;
}

class SupabaseStreakRepository implements StreakRepository {
  SupabaseStreakRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<StreakSnapshot> current() async {
    final raw = await _client.rpc('my_streak');
    if (raw is Map<String, dynamic>) {
      return StreakSnapshot.fromJson(raw);
    }
    if (raw is Map) {
      return StreakSnapshot.fromJson(Map<String, dynamic>.from(raw));
    }
    return StreakSnapshot.empty;
  }
}
