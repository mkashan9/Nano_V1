import 'parent_guidance.dart';

/// PAR-03 guardian invite / link foundations (verified authorization, fake-first).

enum GuardianInviteStatus { open, consumed, revoked }

enum GuardianLinkStatus { active, revoked }

class GuardianInvite {
  const GuardianInvite({
    required this.code,
    required this.childUserId,
    required this.childDisplayName,
    required this.status,
    required this.createdAt,
    this.expiresAt,
  });

  final String code;
  final String childUserId;
  final String childDisplayName;
  final GuardianInviteStatus status;
  final DateTime createdAt;
  final DateTime? expiresAt;

  bool get isOpen => status == GuardianInviteStatus.open;

  bool isExpiredAt(DateTime now) {
    final expires = expiresAt;
    return expires != null && !expires.isAfter(now);
  }

  factory GuardianInvite.fromJson(Map<String, dynamic> json) {
    final statusRaw = '${json['status'] ?? 'open'}';
    return GuardianInvite(
      code: (json['code'] as String? ?? '').trim().toUpperCase(),
      childUserId: json['child_user_id'] as String? ?? '',
      childDisplayName: json['child_display_name'] as String? ?? '',
      status: switch (statusRaw) {
        'consumed' => GuardianInviteStatus.consumed,
        'revoked' => GuardianInviteStatus.revoked,
        _ => GuardianInviteStatus.open,
      },
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.tryParse('${json['expires_at']}'),
    );
  }
}

class GuardianLinkRecord {
  const GuardianLinkRecord({
    required this.guardianId,
    required this.childUserId,
    required this.childDisplayName,
    required this.status,
    required this.linkedAt,
    this.guardianDisplayName,
  });

  final String guardianId;
  final String childUserId;
  final String childDisplayName;
  final GuardianLinkStatus status;
  final DateTime linkedAt;
  final String? guardianDisplayName;

  bool get isActive => status == GuardianLinkStatus.active;

  GuardianChildLink toChildLink() => GuardianChildLink(
        guardianId: guardianId,
        childUserId: childUserId,
        childDisplayName: childDisplayName,
      );

  factory GuardianLinkRecord.fromJson(Map<String, dynamic> json) {
    final statusRaw = '${json['status'] ?? 'active'}';
    return GuardianLinkRecord(
      guardianId: json['guardian_id'] as String? ?? '',
      childUserId: json['child_user_id'] as String? ?? '',
      childDisplayName: json['child_display_name'] as String? ?? '',
      status: statusRaw == 'revoked'
          ? GuardianLinkStatus.revoked
          : GuardianLinkStatus.active,
      linkedAt: DateTime.tryParse('${json['linked_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      guardianDisplayName: json['guardian_display_name'] as String?,
    );
  }
}

enum GuardianLinkDenial {
  none,
  invalidCode,
  inviteUnavailable,
  alreadyLinked,
  notLinked,
  missingActor,
}

class GuardianLinkDecision {
  const GuardianLinkDecision.allow()
      : allowed = true,
        reason = GuardianLinkDenial.none;

  const GuardianLinkDecision.deny(this.reason) : allowed = false;

  final bool allowed;
  final GuardianLinkDenial reason;
}

/// Client-side guardian link rules. Server remains authoritative when live.
abstract final class GuardianLinkPolicy {
  static String normalizeCode(String raw) =>
      raw.trim().toUpperCase().replaceAll(RegExp(r'\s+'), '');

  static bool looksLikeCode(String raw) {
    final code = normalizeCode(raw);
    return RegExp(r'^[A-Z0-9]{4,12}$').hasMatch(code);
  }

  static GuardianLinkDecision canCreateInvite({required String childUserId}) {
    if (childUserId.trim().isEmpty) {
      return const GuardianLinkDecision.deny(GuardianLinkDenial.missingActor);
    }
    return const GuardianLinkDecision.allow();
  }

  static GuardianLinkDecision canAccept({
    required String guardianId,
    required GuardianInvite invite,
    required Iterable<GuardianLinkRecord> existing,
    DateTime? now,
  }) {
    if (guardianId.trim().isEmpty) {
      return const GuardianLinkDecision.deny(GuardianLinkDenial.missingActor);
    }
    if (!invite.isOpen || invite.isExpiredAt(now ?? DateTime.now().toUtc())) {
      return const GuardianLinkDecision.deny(
        GuardianLinkDenial.inviteUnavailable,
      );
    }
    final already = existing.any(
      (link) =>
          link.isActive &&
          link.guardianId == guardianId &&
          link.childUserId == invite.childUserId,
    );
    if (already) {
      return const GuardianLinkDecision.deny(GuardianLinkDenial.alreadyLinked);
    }
    return const GuardianLinkDecision.allow();
  }

  static GuardianLinkDecision canRevoke({
    required String guardianId,
    required String childUserId,
    required Iterable<GuardianLinkRecord> existing,
  }) {
    final found = existing.any(
      (link) =>
          link.isActive &&
          link.guardianId == guardianId &&
          link.childUserId == childUserId,
    );
    if (!found) {
      return const GuardianLinkDecision.deny(GuardianLinkDenial.notLinked);
    }
    return const GuardianLinkDecision.allow();
  }

  static List<GuardianLinkRecord> activeForChild(
    String childUserId,
    Iterable<GuardianLinkRecord> links,
  ) {
    return [
      for (final link in links)
        if (link.isActive && link.childUserId == childUserId) link,
    ];
  }

  static List<GuardianLinkRecord> activeForGuardian(
    String guardianId,
    Iterable<GuardianLinkRecord> links,
  ) {
    return [
      for (final link in links)
        if (link.isActive && link.guardianId == guardianId) link,
    ];
  }
}
