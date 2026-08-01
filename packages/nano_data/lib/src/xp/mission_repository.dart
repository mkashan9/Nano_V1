import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// XP-04 read side for the current period's missions.
abstract class MissionRepository {
  Future<List<MissionProgressView>> current();
}

class FakeMissionRepository implements MissionRepository {
  FakeMissionRepository({List<MissionProgressView>? missions})
      : _missions = [...?missions];

  final List<MissionProgressView> _missions;

  @override
  Future<List<MissionProgressView>> current() async => List.of(_missions);

  void replaceAll(List<MissionProgressView> next) {
    _missions
      ..clear()
      ..addAll(next);
  }
}

class SupabaseMissionRepository implements MissionRepository {
  SupabaseMissionRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<MissionProgressView>> current() async {
    final raw = await _client.rpc('my_missions');
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map(
          (row) => MissionProgressView.fromRow(Map<String, dynamic>.from(row)),
        )
        .toList();
  }
}
