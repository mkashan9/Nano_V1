import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake defaults to full access', () async {
    final repo = FakeIndependentAccessRepository();
    final access = await repo.loadAccess(userId: 'u1');
    expect(access.tier, IndependentAccessTier.full);
    expect(access.allows(IndependentFeature.games), isTrue);
  });

  test('seeded restricted access can be reloaded', () async {
    final repo = FakeIndependentAccessRepository(
      seed: IndependentAccessPolicy.restricted(),
    );
    final access = await repo.loadAccess(userId: 'u1');
    expect(access.isReduced, isTrue);
    expect(access.allows(IndependentFeature.games), isFalse);
  });

  test('alwaysFail surfaces errors', () async {
    final repo = FakeIndependentAccessRepository()..alwaysFail = true;
    expect(repo.loadAccess(userId: 'u1'), throwsStateError);
  });
}
