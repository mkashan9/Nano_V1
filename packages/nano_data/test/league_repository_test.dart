import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake league join is idempotent and returns rank card', () async {
    final repo = FakeLeagueRepository();
    final before = await repo.currentStatus();
    expect(before.joined, isFalse);

    final joined = await repo.joinCurrent();
    expect(joined.joined, isTrue);
    expect(joined.rank, 2);
    expect(joined.weekXp, 40);
    expect(repo.joinCalls, 1);

    final again = await repo.joinCurrent();
    expect(again.joined, isTrue);
    expect(repo.joinCalls, 2);
  });

  test('fake leaderboard returns privacy-safe labels after join', () async {
    final repo = FakeLeagueRepository();
    final empty = await repo.leaderboard();
    expect(empty.joined, isFalse);

    await repo.joinCurrent();
    final board = await repo.leaderboard();
    expect(board.joined, isTrue);
    expect(board.entries, isNotEmpty);
    expect(board.entries.any((e) => e.isMe), isTrue);
    expect(
      board.entries.every((e) => !e.displayLabel.contains('Alpha')),
      isTrue,
    );
  });

  test('fake challenge create accept rematch flow', () async {
    final repo = FakeLeagueRepository();
    await repo.joinCurrent();
    final board = await repo.leaderboard();
    final token = board.entries.firstWhere((e) => e.canChallenge).targetToken!;
    final created = await repo.createChallenge(token);
    expect(created.status, LeagueChallengeStatus.pending);

    final asOpponent = LeagueChallenge(
      id: created.id,
      status: created.status,
      ruleSlug: created.ruleSlug,
      titleEn: created.titleEn,
      peerLabel: 'Ali',
      iAmChallenger: false,
      expiresAt: created.expiresAt,
      gameVersionId: created.gameVersionId,
    );
    // Seed opponent view into repo list via respond on fake (same id).
    final accepted = await repo.respondChallenge(
      challengeId: asOpponent.id,
      accept: true,
    );
    expect(accepted.status, LeagueChallengeStatus.accepted);

    final settled = await repo.recordChallengeScore(accepted.id);
    expect(settled.status, LeagueChallengeStatus.completed);
    final rematch = await repo.createRematch(settled.id);
    expect(rematch.rematchOf, settled.id);
  });
}
