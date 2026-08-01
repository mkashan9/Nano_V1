import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('fake ledger balance and credits stay consistent', () async {
    final repo = FakeXpLedgerRepository(
      balanceValue: XpBalance.empty,
      entries: const [],
    );
    expect((await repo.balance()).total, 0);

    repo.credit(
      XpLedgerEntry(
        id: 'e1',
        userId: 'u1',
        amount: 10,
        sourceKind: XpSourceKind.videoCompletion,
        sourceId: 'tv-1',
        awardedAt: DateTime.utc(2026, 8, 2),
      ),
    );

    final balance = await repo.balance();
    expect(balance.total, 10);
    expect((await repo.recent()).single.amount, 10);
  });

  test('home reads XP from the ledger when one is attached', () async {
    final xp = FakeXpLedgerRepository(
      balanceValue: const XpBalance(
        total: 40,
        today: 40,
        dailyCap: 200,
        remainingToday: 160,
      ),
    );
    final home = FakeStudentHomeRepository(xpLedger: xp);
    final summary = await home.loadHome(
      userId: 'u1',
      learnerName: 'Ali',
    );
    expect(summary.xp, 40);
    expect(summary.level.level, 1);
  });

  test('home keeps the fixture XP when no ledger is attached', () async {
    final home = FakeStudentHomeRepository(fixtureXp: 560);
    final summary = await home.loadHome(
      userId: 'u1',
      learnerName: 'Ali',
    );
    expect(summary.xp, 560);
  });
}
