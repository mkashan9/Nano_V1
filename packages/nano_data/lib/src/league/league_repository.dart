import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// LGE-01/02 weekly league status + leaderboard.
abstract class LeagueRepository {
  Future<LeagueStatus> currentStatus();

  Future<LeagueStatus> joinCurrent();

  Future<LeagueBoard> leaderboard({int limit = 10});
}

class FakeLeagueRepository implements LeagueRepository {
  FakeLeagueRepository({
    LeagueStatus? status,
    LeagueBoard? board,
  })  : _status = status ??
            LeagueStatus.notJoined(
              weekKey: '2026-W31',
              startsAt: DateTime.utc(2026, 7, 27),
              endsAt: DateTime.utc(2026, 8, 3),
            ),
        _board = board;

  LeagueStatus _status;
  LeagueBoard? _board;
  var joinCalls = 0;
  var boardCalls = 0;

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
    _board ??= LeagueBoard(
      joined: true,
      weekKey: _status.weekKey,
      myRank: 2,
      myWeekXp: 40,
      divisionSlug: 'bronze',
      divisionTitleEn: 'Bronze',
      divisionTitleUr: 'کانسی',
      entries: const [
        LeagueBoardEntry(rank: 1, weekXp: 80, displayLabel: 'Sara'),
        LeagueBoardEntry(
          rank: 2,
          weekXp: 40,
          displayLabel: 'Ali',
          isMe: true,
        ),
        LeagueBoardEntry(rank: 3, weekXp: 20, displayLabel: 'Learner'),
      ],
    );
    return _status;
  }

  @override
  Future<LeagueBoard> leaderboard({int limit = 10}) async {
    boardCalls += 1;
    if (!_status.joined) {
      return LeagueBoard(
        joined: false,
        weekKey: _status.weekKey,
        entries: const [],
      );
    }
    final board = _board ??
        LeagueBoard(
          joined: true,
          weekKey: _status.weekKey,
          myRank: _status.rank,
          myWeekXp: _status.weekXp,
          divisionSlug: _status.divisionSlug,
          divisionTitleEn: _status.divisionTitleEn,
          divisionTitleUr: _status.divisionTitleUr,
          entries: [
            LeagueBoardEntry(
              rank: _status.rank ?? 1,
              weekXp: _status.weekXp,
              displayLabel: 'Ali',
              isMe: true,
            ),
          ],
        );
    return LeagueBoard(
      joined: board.joined,
      weekKey: board.weekKey,
      myRank: board.myRank,
      myWeekXp: board.myWeekXp,
      divisionSlug: board.divisionSlug,
      divisionTitleEn: board.divisionTitleEn,
      divisionTitleUr: board.divisionTitleUr,
      entries: [
        for (final e in board.entries)
          if (e.rank <= limit || e.isMe) e,
      ],
    );
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

  @override
  Future<LeagueBoard> leaderboard({int limit = 10}) async {
    final raw = await _client.rpc(
      'my_league_leaderboard',
      params: {'p_limit': limit},
    );
    if (raw is! Map) {
      throw StateError('Leaderboard unavailable.');
    }
    return LeagueBoard.fromJson(Map<String, dynamic>.from(raw));
  }
}
