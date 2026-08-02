import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// LGE-01/02/03 weekly league status, board, and peer challenges.
abstract class LeagueRepository {
  Future<LeagueStatus> currentStatus();

  Future<LeagueStatus> joinCurrent();

  Future<LeagueBoard> leaderboard({int limit = 10});

  Future<LeagueChallenge> createChallenge(String targetToken);

  Future<LeagueChallenge> respondChallenge({
    required String challengeId,
    required bool accept,
  });

  Future<List<LeagueChallenge>> listChallenges();

  Future<LeagueChallenge> recordChallengeScore(String challengeId);

  Future<LeagueChallenge> createRematch(String challengeId);
}

class FakeLeagueRepository implements LeagueRepository {
  FakeLeagueRepository({
    LeagueStatus? status,
    LeagueBoard? board,
    List<LeagueChallenge>? challenges,
  })  : _status = status ??
            LeagueStatus.notJoined(
              weekKey: '2026-W31',
              startsAt: DateTime.utc(2026, 7, 27),
              endsAt: DateTime.utc(2026, 8, 3),
            ),
        _board = board,
        _challenges = [...?challenges];

  LeagueStatus _status;
  LeagueBoard? _board;
  final List<LeagueChallenge> _challenges;
  var joinCalls = 0;
  var boardCalls = 0;
  var challengeCalls = 0;

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
        LeagueBoardEntry(
          rank: 1,
          weekXp: 80,
          displayLabel: 'Sara',
          targetToken: 'tok-sara',
        ),
        LeagueBoardEntry(
          rank: 2,
          weekXp: 40,
          displayLabel: 'Ali',
          isMe: true,
        ),
        LeagueBoardEntry(
          rank: 3,
          weekXp: 20,
          displayLabel: 'Learner',
        ),
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

  @override
  Future<LeagueChallenge> createChallenge(String targetToken) async {
    challengeCalls += 1;
    if (targetToken.isEmpty) {
      throw StateError('Missing target');
    }
    final challenge = LeagueChallenge(
      id: 'ch-${_challenges.length + 1}',
      status: LeagueChallengeStatus.pending,
      ruleSlug: 'number_rush_duel',
      titleEn: 'Number Rush duel',
      peerLabel: 'Sara',
      iAmChallenger: true,
      expiresAt: DateTime.utc(2026, 8, 3),
      gameVersionId: 'v-number',
    );
    _challenges.insert(0, challenge);
    return challenge;
  }

  @override
  Future<LeagueChallenge> respondChallenge({
    required String challengeId,
    required bool accept,
  }) async {
    final idx = _challenges.indexWhere((c) => c.id == challengeId);
    if (idx < 0) throw StateError('Missing challenge');
    final current = _challenges[idx];
    final next = LeagueChallenge(
      id: current.id,
      status: accept
          ? LeagueChallengeStatus.accepted
          : LeagueChallengeStatus.declined,
      ruleSlug: current.ruleSlug,
      titleEn: current.titleEn,
      titleUr: current.titleUr,
      peerLabel: current.peerLabel,
      iAmChallenger: current.iAmChallenger,
      expiresAt: current.expiresAt,
      gameVersionId: current.gameVersionId,
    );
    _challenges[idx] = next;
    return next;
  }

  @override
  Future<List<LeagueChallenge>> listChallenges() async =>
      List.unmodifiable(_challenges);

  @override
  Future<LeagueChallenge> recordChallengeScore(String challengeId) async {
    final idx = _challenges.indexWhere((c) => c.id == challengeId);
    if (idx < 0) throw StateError('Missing challenge');
    final current = _challenges[idx];
    final next = LeagueChallenge(
      id: current.id,
      status: LeagueChallengeStatus.completed,
      ruleSlug: current.ruleSlug,
      titleEn: current.titleEn,
      titleUr: current.titleUr,
      peerLabel: current.peerLabel,
      iAmChallenger: current.iAmChallenger,
      expiresAt: current.expiresAt,
      gameVersionId: current.gameVersionId,
      myScore: 5,
      peerScore: 3,
      outcome: LeagueChallengeOutcome.challengerWin,
    );
    _challenges[idx] = next;
    return next;
  }

  @override
  Future<LeagueChallenge> createRematch(String challengeId) async {
    final parent = _challenges.firstWhere((c) => c.id == challengeId);
    final rematch = LeagueChallenge(
      id: 'ch-rematch-${_challenges.length + 1}',
      status: LeagueChallengeStatus.pending,
      ruleSlug: parent.ruleSlug,
      titleEn: parent.titleEn,
      titleUr: parent.titleUr,
      peerLabel: parent.peerLabel,
      iAmChallenger: true,
      expiresAt: DateTime.utc(2026, 8, 4),
      gameVersionId: parent.gameVersionId,
      rematchOf: parent.id,
    );
    _challenges.insert(0, rematch);
    return rematch;
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

  @override
  Future<LeagueChallenge> createChallenge(String targetToken) async {
    final raw = await _client.rpc(
      'create_league_challenge',
      params: {
        'p_target_token': targetToken,
        'p_rule_slug': 'number_rush_duel',
      },
    );
    if (raw is! Map) throw StateError('Could not create challenge.');
    return LeagueChallenge.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<LeagueChallenge> respondChallenge({
    required String challengeId,
    required bool accept,
  }) async {
    final raw = await _client.rpc(
      'respond_league_challenge',
      params: {
        'p_challenge_id': challengeId,
        'p_accept': accept,
      },
    );
    if (raw is! Map) throw StateError('Could not respond.');
    return LeagueChallenge.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<LeagueChallenge>> listChallenges() async {
    final raw = await _client.rpc('my_league_challenges');
    if (raw is! Map) return const [];
    final items = raw['challenges'];
    if (items is! List) return const [];
    return [
      for (final row in items)
        if (row is Map)
          LeagueChallenge.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<LeagueChallenge> recordChallengeScore(String challengeId) async {
    final raw = await _client.rpc(
      'record_league_challenge_score',
      params: {'p_challenge_id': challengeId},
    );
    if (raw is! Map) throw StateError('Could not record score.');
    return LeagueChallenge.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<LeagueChallenge> createRematch(String challengeId) async {
    final raw = await _client.rpc(
      'create_league_rematch',
      params: {'p_challenge_id': challengeId},
    );
    if (raw is! Map) throw StateError('Could not rematch.');
    return LeagueChallenge.fromJson(Map<String, dynamic>.from(raw));
  }
}
