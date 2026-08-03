import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);

  GuardianInvite openInvite() => GuardianInvite(
        code: 'GUARD01',
        childUserId: 'child-1',
        childDisplayName: 'Ali',
        status: GuardianInviteStatus.open,
        createdAt: now,
        expiresAt: now.add(const Duration(days: 7)),
      );

  test('normalize and looksLikeCode', () {
    expect(GuardianLinkPolicy.normalizeCode(' guard01 '), 'GUARD01');
    expect(GuardianLinkPolicy.looksLikeCode('GUARD01'), isTrue);
    expect(GuardianLinkPolicy.looksLikeCode('ab'), isFalse);
  });

  test('canAccept rejects missing guardian and consumed invite', () {
    expect(
      GuardianLinkPolicy.canAccept(
        guardianId: '',
        invite: openInvite(),
        existing: const [],
        now: now,
      ).reason,
      GuardianLinkDenial.missingActor,
    );

    final consumed = GuardianInvite(
      code: 'GUARD01',
      childUserId: 'child-1',
      childDisplayName: 'Ali',
      status: GuardianInviteStatus.consumed,
      createdAt: now,
    );
    expect(
      GuardianLinkPolicy.canAccept(
        guardianId: 'g1',
        invite: consumed,
        existing: const [],
        now: now,
      ).reason,
      GuardianLinkDenial.inviteUnavailable,
    );
  });

  test('canAccept rejects already linked pair', () {
    final existing = [
      GuardianLinkRecord(
        guardianId: 'g1',
        childUserId: 'child-1',
        childDisplayName: 'Ali',
        status: GuardianLinkStatus.active,
        linkedAt: now,
      ),
    ];
    expect(
      GuardianLinkPolicy.canAccept(
        guardianId: 'g1',
        invite: openInvite(),
        existing: existing,
        now: now,
      ).reason,
      GuardianLinkDenial.alreadyLinked,
    );
  });

  test('active filters and revoke gate', () {
    final links = [
      GuardianLinkRecord(
        guardianId: 'g1',
        childUserId: 'child-1',
        childDisplayName: 'Ali',
        status: GuardianLinkStatus.active,
        linkedAt: now,
      ),
      GuardianLinkRecord(
        guardianId: 'g2',
        childUserId: 'child-1',
        childDisplayName: 'Ali',
        status: GuardianLinkStatus.revoked,
        linkedAt: now,
      ),
    ];
    expect(GuardianLinkPolicy.activeForChild('child-1', links), hasLength(1));
    expect(
      GuardianLinkPolicy.canRevoke(
        guardianId: 'g1',
        childUserId: 'child-1',
        existing: links,
      ).allowed,
      isTrue,
    );
    expect(
      GuardianLinkPolicy.canRevoke(
        guardianId: 'g2',
        childUserId: 'child-1',
        existing: links,
      ).reason,
      GuardianLinkDenial.notLinked,
    );
  });
}
