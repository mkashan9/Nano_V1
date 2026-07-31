import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('independent student flag', () {
    const indie = Profile(
      id: TenancyFixtures.indieId,
      displayName: 'Indie Ali',
      accountKind: AccountKind.independentStudent,
      status: MembershipStatus.active,
    );
    expect(indie.isIndependentStudent, isTrue);
  });

  test('fixture schools are distinct', () {
    expect(TenancyFixtures.alpha.code, 'ALPHA01');
    expect(TenancyFixtures.beta.code, 'BETA02');
    expect(TenancyFixtures.alpha.id, isNot(TenancyFixtures.beta.id));
  });
}
