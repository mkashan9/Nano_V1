import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('create accept list revoke and access policy', () async {
    final repo = FakeGuardianLinkRepository();
    final invite = await repo.createInvite(
      childUserId: 'child-1',
      childDisplayName: 'Ali',
    );
    expect(invite.code, 'GUARD01');
    expect(invite.isOpen, isTrue);

    final preview = await repo.previewInvite('guard01');
    expect(preview.childDisplayName, 'Ali');

    final linked = await repo.acceptInvite(
      guardianId: 'guardian-demo',
      code: invite.code,
      guardianDisplayName: 'Demo guardian',
    );
    expect(linked.isActive, isTrue);

    final forChild = await repo.listLinksForChild(childUserId: 'child-1');
    expect(forChild, hasLength(1));
    expect(
      await repo.listLinksForGuardian(guardianId: 'guardian-demo'),
      hasLength(1),
    );

    expect(
      GuardianAccessPolicy.canViewChild(
        guardianId: 'guardian-demo',
        childUserId: 'child-1',
        links: repo.activeChildLinks,
      ),
      isTrue,
    );
    expect(
      GuardianAccessPolicy.canViewChild(
        guardianId: 'stranger',
        childUserId: 'child-1',
        links: repo.activeChildLinks,
      ),
      isFalse,
    );

    await repo.revokeLink(
      guardianId: 'guardian-demo',
      childUserId: 'child-1',
    );
    expect(await repo.listLinksForChild(childUserId: 'child-1'), isEmpty);
    expect(
      GuardianAccessPolicy.canViewChild(
        guardianId: 'guardian-demo',
        childUserId: 'child-1',
        links: repo.activeChildLinks,
      ),
      isFalse,
    );
  });

  test('accept without open invite fails', () async {
    final repo = FakeGuardianLinkRepository();
    expect(
      () => repo.acceptInvite(guardianId: 'g1', code: 'NOPE01'),
      throwsStateError,
    );
  });
}
