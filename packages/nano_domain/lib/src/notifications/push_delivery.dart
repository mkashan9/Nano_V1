/// NOT-01 push delivery, device tokens, and lock-screen-safe previews.

enum DeviceTokenStatus { active, invalid }

class DeviceToken {
  const DeviceToken({
    required this.token,
    required this.userId,
    required this.platform,
    required this.status,
    required this.updatedAt,
  });

  final String token;
  final String userId;
  final String platform;
  final DeviceTokenStatus status;
  final DateTime updatedAt;

  bool get isActive => status == DeviceTokenStatus.active;

  DeviceToken copyWith({
    DeviceTokenStatus? status,
    DateTime? updatedAt,
  }) {
    return DeviceToken(
      token: token,
      userId: userId,
      platform: platform,
      status: status ?? this.status,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  factory DeviceToken.fromJson(Map<String, dynamic> json) {
    final statusRaw = '${json['status'] ?? 'active'}';
    return DeviceToken(
      token: json['token'] as String? ?? '',
      userId: json['user_id'] as String? ?? '',
      platform: json['platform'] as String? ?? 'unknown',
      status: statusRaw == 'invalid'
          ? DeviceTokenStatus.invalid
          : DeviceTokenStatus.active,
      updatedAt: DateTime.tryParse('${json['updated_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
    );
  }
}

class PushEvent {
  const PushEvent({
    required this.eventId,
    required this.recipientUserId,
    required this.category,
    required this.title,
    required this.body,
    this.deepLinkPath = '/',
  });

  final String eventId;
  final String recipientUserId;
  final String category;
  final String title;
  final String body;
  final String deepLinkPath;
}

enum PushDeliveryOutcome {
  delivered,
  duplicated,
  noActiveToken,
  rejected,
}

class PushDeliveryResult {
  const PushDeliveryResult({
    required this.outcome,
    this.inboxItemId,
    this.lockScreenPreview,
  });

  final PushDeliveryOutcome outcome;
  final String? inboxItemId;
  final String? lockScreenPreview;

  bool get didCreateInboxItem =>
      outcome == PushDeliveryOutcome.delivered && inboxItemId != null;
}

/// Client-side push rules. Server remains authoritative when live.
abstract final class PushDeliveryPolicy {
  static const sensitiveCategories = <String>{
    'marks',
    'results',
    'payment',
    'account',
  };

  /// Lock-screen text never includes marks/scores or private detail.
  static String lockScreenPreview({
    required String category,
    required String title,
    required String body,
  }) {
    final cat = category.trim().toLowerCase();
    if (sensitiveCategories.contains(cat)) {
      return 'You have a new Nano update';
    }
    final lower = body.toLowerCase();
    if (lower.contains('mark') ||
        lower.contains('score') ||
        lower.contains('grade') ||
        RegExp(r'\b\d{1,3}%\b').hasMatch(body)) {
      return title.trim().isEmpty ? 'You have a new Nano update' : title.trim();
    }
    return body.trim().isEmpty ? title.trim() : body.trim();
  }

  static bool looksLikeToken(String token) {
    final t = token.trim();
    return t.length >= 8 && !t.toLowerCase().contains('invalid');
  }
}
