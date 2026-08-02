import 'package:nano_data/nano_data.dart';
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
}
