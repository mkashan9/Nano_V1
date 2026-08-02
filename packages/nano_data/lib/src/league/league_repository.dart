import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// LGE-01 weekly league personal status.
abstract class LeagueRepository {
  Future<LeagueStatus> currentStatus();

  Future<LeagueStatus> joinCurrent();
}

class FakeLeagueRepository implements LeagueRepository {
  FakeLeagueRepository({LeagueStatus? status})
      : _status = status ??
            LeagueStatus.notJoined(
              weekKey: '2026-W31',
              startsAt: DateTime.utc(2026, 7, 27),
              endsAt: DateTime.utc(2026, 8, 3),
            );

  LeagueStatus _status;
  var joinCalls = 0;

  @override
  Future<LeagueStatus> currentStatus() async => _status;

  @override
  Future<LeagueStatus> joinCurrent() async {
    joinCalls += 1;
    if (_status.joined) return _status;
    _status = LeagueStatus(
      joined: true,
      weekKey: _status.weekKey,
      startsAt: _status.startsAt,
      endsAt: _status.endsAt,
      status: 'open',
      weekXp: 40,
      rank: 2,
      peerCount: 5,
      divisionSlug: 'bronze',
      divisionTitleEn: 'Bronze',
      divisionTitleUr: 'کانسی',
    );
    return _status;
  }
}

class SupabaseLeagueRepository implements LeagueRepository {
  SupabaseLeagueRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<LeagueStatus> currentStatus() async {
    final raw = await _client.rpc('my_league_status');
    if (raw is! Map) {
      throw StateError('League status unavailable.');
    }
    return LeagueStatus.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<LeagueStatus> joinCurrent() async {
    final raw = await _client.rpc('join_current_league');
    if (raw is! Map) {
      throw StateError('Could not join league.');
    }
    return LeagueStatus.fromJson(Map<String, dynamic>.from(raw));
  }
}
