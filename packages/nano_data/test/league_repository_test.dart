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
}
