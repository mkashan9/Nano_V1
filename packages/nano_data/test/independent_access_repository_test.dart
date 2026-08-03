import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake defaults to a trial plan with full access', () async {
    final repo = FakeIndependentAccessRepository();
    final plan = await repo.loadPlan(userId: 'u1');
    expect(plan.kind, IndependentPlanKind.trial);
    final access = await repo.loadAccess(userId: 'u1');
    expect(access.allows(IndependentFeature.games), isTrue);
    expect(access.planLabel, 'Trial');
  });

  test('seeded restricted access maps to expired plan', () async {
    final repo = FakeIndependentAccessRepository(
      seed: IndependentAccessPolicy.restricted(),
    );
    final access = await repo.loadAccess(userId: 'u1');
    expect(access.isReduced, isTrue);
    expect((await repo.loadPlan(userId: 'u1')).kind, IndependentPlanKind.expired);
  });

  test('applyPlan can start a trial from free', () async {
    final repo = FakeIndependentAccessRepository(
      plan: const IndependentPlanSnapshot(kind: IndependentPlanKind.free),
    );
    final plan = await repo.applyPlan(
      userId: 'u1',
      kind: IndependentPlanKind.trial,
    );
    expect(plan.kind, IndependentPlanKind.trial);
    expect(plan.daysRemaining, greaterThan(0));
  });

  test('applyPlan expire reduces games', () async {
    final repo = FakeIndependentAccessRepository();
    await repo.applyPlan(userId: 'u1', kind: IndependentPlanKind.expired);
    final access = await repo.loadAccess(userId: 'u1');
    expect(access.allows(IndependentFeature.games), isFalse);
    expect(access.allows(IndependentFeature.learning), isTrue);
  });

  test('alwaysFail surfaces errors', () async {
    final repo = FakeIndependentAccessRepository()..alwaysFail = true;
    expect(repo.loadAccess(userId: 'u1'), throwsStateError);
    expect(repo.loadPlan(userId: 'u1'), throwsStateError);
  });
}
