import 'package:nano_domain/nano_domain.dart';

/// PAR-03 guardian invite create / accept / list / revoke (fake-first).
abstract class GuardianLinkRepository {
  Future<GuardianInvite> createInvite({
    required String childUserId,
    required String childDisplayName,
  });

  Future<GuardianInvite?> currentInvite({required String childUserId});

  Future<GuardianInvite> previewInvite(String code);

  Future<GuardianLinkRecord> acceptInvite({
    required String guardianId,
    required String code,
    String? guardianDisplayName,
  });

  Future<List<GuardianLinkRecord>> listLinksForChild({
    required String childUserId,
  });

  Future<List<GuardianLinkRecord>> listLinksForGuardian({
    required String guardianId,
  });

  Future<GuardianLinkRecord> revokeLink({
    required String guardianId,
    required String childUserId,
  });
}

class FakeGuardianLinkRepository implements GuardianLinkRepository {
  FakeGuardianLinkRepository({
    List<GuardianInvite>? invites,
    List<GuardianLinkRecord>? links,
    this.alwaysFail = false,
  })  : _invites = List.of(invites ?? const []),
        _links = List.of(links ?? const []);

  final List<GuardianInvite> _invites;
  final List<GuardianLinkRecord> _links;
  bool alwaysFail;
  var _seq = 0;

  /// Active PAR-01-shaped links for access-policy tests.
  List<GuardianChildLink> get activeChildLinks => [
        for (final link in _links)
          if (link.isActive) link.toChildLink(),
      ];

  @override
  Future<GuardianInvite> createInvite({
    required String childUserId,
    required String childDisplayName,
  }) async {
    if (alwaysFail) throw StateError('Invite create failed');
    final decision =
        GuardianLinkPolicy.canCreateInvite(childUserId: childUserId);
    if (!decision.allowed) throw StateError(decision.reason.name);

    // Only one open invite per child.
    for (var i = 0; i < _invites.length; i++) {
      final invite = _invites[i];
      if (invite.childUserId == childUserId && invite.isOpen) {
        _invites[i] = GuardianInvite(
          code: invite.code,
          childUserId: invite.childUserId,
          childDisplayName: invite.childDisplayName,
          status: GuardianInviteStatus.revoked,
          createdAt: invite.createdAt,
          expiresAt: invite.expiresAt,
        );
      }
    }

    _seq += 1;
    final now = DateTime.now().toUtc();
    final created = GuardianInvite(
      code: 'GUARD${_seq.toString().padLeft(2, '0')}',
      childUserId: childUserId.trim(),
      childDisplayName: childDisplayName.trim().isEmpty
          ? 'Learner'
          : childDisplayName.trim(),
      status: GuardianInviteStatus.open,
      createdAt: now,
      expiresAt: now.add(const Duration(days: 7)),
    );
    _invites.insert(0, created);
    return created;
  }

  @override
  Future<GuardianInvite?> currentInvite({required String childUserId}) async {
    if (alwaysFail) throw StateError('Invite lookup failed');
    final now = DateTime.now().toUtc();
    for (final invite in _invites) {
      if (invite.childUserId == childUserId &&
          invite.isOpen &&
          !invite.isExpiredAt(now)) {
        return invite;
      }
    }
    return null;
  }

  @override
  Future<GuardianInvite> previewInvite(String code) async {
    if (alwaysFail) throw StateError('Invite lookup failed');
    final normalized = GuardianLinkPolicy.normalizeCode(code);
    if (!GuardianLinkPolicy.looksLikeCode(normalized)) {
      throw StateError(GuardianLinkDenial.invalidCode.name);
    }
    GuardianInvite? invite;
    for (final item in _invites) {
      if (item.code == normalized) {
        invite = item;
        break;
      }
    }
    if (invite == null ||
        !invite.isOpen ||
        invite.isExpiredAt(DateTime.now().toUtc())) {
      throw StateError(GuardianLinkDenial.inviteUnavailable.name);
    }
    return invite;
  }

  @override
  Future<GuardianLinkRecord> acceptInvite({
    required String guardianId,
    required String code,
    String? guardianDisplayName,
  }) async {
    if (alwaysFail) throw StateError('Accept failed');
    final invite = await previewInvite(code);
    final decision = GuardianLinkPolicy.canAccept(
      guardianId: guardianId,
      invite: invite,
      existing: _links,
    );
    if (!decision.allowed) throw StateError(decision.reason.name);

    final inviteIndex = _invites.indexWhere((item) => item.code == invite.code);
    if (inviteIndex >= 0) {
      final current = _invites[inviteIndex];
      _invites[inviteIndex] = GuardianInvite(
        code: current.code,
        childUserId: current.childUserId,
        childDisplayName: current.childDisplayName,
        status: GuardianInviteStatus.consumed,
        createdAt: current.createdAt,
        expiresAt: current.expiresAt,
      );
    }

    final linked = GuardianLinkRecord(
      guardianId: guardianId.trim(),
      childUserId: invite.childUserId,
      childDisplayName: invite.childDisplayName,
      status: GuardianLinkStatus.active,
      linkedAt: DateTime.now().toUtc(),
      guardianDisplayName:
          (guardianDisplayName == null || guardianDisplayName.trim().isEmpty)
              ? 'Guardian'
              : guardianDisplayName.trim(),
    );
    _links.insert(0, linked);
    return linked;
  }

  @override
  Future<List<GuardianLinkRecord>> listLinksForChild({
    required String childUserId,
  }) async {
    if (alwaysFail) throw StateError('Links unavailable');
    return GuardianLinkPolicy.activeForChild(childUserId, _links);
  }

  @override
  Future<List<GuardianLinkRecord>> listLinksForGuardian({
    required String guardianId,
  }) async {
    if (alwaysFail) throw StateError('Links unavailable');
    return GuardianLinkPolicy.activeForGuardian(guardianId, _links);
  }

  @override
  Future<GuardianLinkRecord> revokeLink({
    required String guardianId,
    required String childUserId,
  }) async {
    if (alwaysFail) throw StateError('Revoke failed');
    final decision = GuardianLinkPolicy.canRevoke(
      guardianId: guardianId,
      childUserId: childUserId,
      existing: _links,
    );
    if (!decision.allowed) throw StateError(decision.reason.name);
    final index = _links.indexWhere(
      (link) =>
          link.isActive &&
          link.guardianId == guardianId &&
          link.childUserId == childUserId,
    );
    final current = _links[index];
    final revoked = GuardianLinkRecord(
      guardianId: current.guardianId,
      childUserId: current.childUserId,
      childDisplayName: current.childDisplayName,
      status: GuardianLinkStatus.revoked,
      linkedAt: current.linkedAt,
      guardianDisplayName: current.guardianDisplayName,
    );
    _links[index] = revoked;
    return revoked;
  }
}
