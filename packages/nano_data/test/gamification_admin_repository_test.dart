import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('policy and level edits update snapshot', () async {
    final repo = FakeGamificationAdminRepository();
    await repo.setDailyCap(300);
    await repo.setAwardAmount(sourceKind: 'quiz_pass', amount: 40);
    await repo.setLevelStep(200);
    final snap = await repo.load();
    expect(snap.dailyCap, 300);
    expect(
      snap.awardRules.firstWhere((r) => r.sourceKind == 'quiz_pass').amount,
      40,
    );
    expect(snap.xpPerLevel, 200);
  });

  test('manual adjust requires reason', () async {
    final repo = FakeGamificationAdminRepository();
    expect(
      () => repo.adjustXp(
        userId: TenancyFixtures.aliAlphaId,
        amount: 5,
        reason: '  ',
      ),
      throwsStateError,
    );
    final result = await repo.adjustXp(
      userId: TenancyFixtures.aliAlphaId,
      amount: 5,
      reason: 'Goodwill',
    );
    expect(result.amount, 5);
    expect(repo.adjustments, hasLength(1));
  });
}
