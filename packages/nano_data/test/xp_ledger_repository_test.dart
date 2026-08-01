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

  test('home reads XP and level from the ledger when one is attached', () async {
    final xp = FakeXpLedgerRepository(
      balanceValue: const XpBalance(
        total: 560,
        today: 40,
        dailyCap: 200,
        remainingToday: 160,
        level: 3,
        xpIntoLevel: 60,
        xpToNext: 190,
        xpPerLevel: 250,
      ),
    );
    final home = FakeStudentHomeRepository(xpLedger: xp);
    final summary = await home.loadHome(
      userId: 'u1',
      learnerName: 'Ali',
    );
    expect(summary.xp, 560);
    expect(summary.level.level, 3);
    expect(summary.level.xpIntoLevel, 60);
    expect(summary.levelProgress, isNotNull);
  });

  test('home keeps the fixture XP when no ledger is attached', () async {
    final home = FakeStudentHomeRepository(fixtureXp: 560);
    final summary = await home.loadHome(
      userId: 'u1',
      learnerName: 'Ali',
    );
    expect(summary.xp, 560);
    expect(summary.levelProgress, isNull);
    expect(summary.level.level, 3);
  });

  test('fake credit refreshes the derived level', () async {
    final repo = FakeXpLedgerRepository(balanceValue: XpBalance.empty);
    repo.credit(
      XpLedgerEntry(
        id: 'e1',
        userId: 'u1',
        amount: 250,
        sourceKind: XpSourceKind.quizPass,
        sourceId: 'q-1',
        awardedAt: DateTime.utc(2026, 8, 2),
      ),
    );
    final balance = await repo.balance();
    expect(balance.total, 250);
    expect(balance.level, 2);
    expect(balance.xpIntoLevel, 0);
  });
}
