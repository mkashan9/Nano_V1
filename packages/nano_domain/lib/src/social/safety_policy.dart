/// SAFE-03 content / rate-limit policy models (client mapping).
enum SafetyActionKey {
  friendRequest,
  userReport,
  communityMessage,
}

extension SafetyActionKeyWire on SafetyActionKey {
  String get wire {
    switch (this) {
      case SafetyActionKey.friendRequest:
        return 'friend_request';
      case SafetyActionKey.userReport:
        return 'user_report';
      case SafetyActionKey.communityMessage:
        return 'community_message';
    }
  }
}

class SafetyTextCheck {
  const SafetyTextCheck({
    required this.allowed,
    this.code,
    this.message,
  });

  final bool allowed;
  final String? code;
  final String? message;

  factory SafetyTextCheck.fromJson(Map<String, dynamic> json) {
    return SafetyTextCheck(
      allowed: json['allowed'] as bool? ?? false,
      code: json['code'] as String?,
      message: json['message'] as String?,
    );
  }
}

class SafetyRateStatus {
  const SafetyRateStatus({
    required this.actionKey,
    required this.configured,
    this.isEnabled = true,
    this.windowSeconds = 0,
    this.maxCount = 0,
    this.used = 0,
    this.remaining = 0,
  });

  final String actionKey;
  final bool configured;
  final bool isEnabled;
  final int windowSeconds;
  final int maxCount;
  final int used;
  final int remaining;

  factory SafetyRateStatus.fromJson(Map<String, dynamic> json) {
    return SafetyRateStatus(
      actionKey: json['action_key'] as String? ?? '',
      configured: json['configured'] as bool? ?? false,
      isEnabled: json['is_enabled'] as bool? ?? true,
      windowSeconds: json['window_seconds'] as int? ?? 0,
      maxCount: json['max_count'] as int? ?? 0,
      used: json['used'] as int? ?? 0,
      remaining: json['remaining'] as int? ?? 0,
    );
  }
}

/// Maps SAFE-03 SQL states to short EN copy for snackbars.
String safetyPolicyMessage(String raw, {required bool isUrdu}) {
  final text = raw.toLowerCase();
  if (text.contains('ns061') || text.contains('too many')) {
    return isUrdu
        ? 'بہت زیادہ کوششیں۔ تھوڑی دیر بعد دوبارہ کوشش کریں۔'
        : 'Too many attempts. Please wait and try again.';
  }
  if (text.contains('ns062') || text.contains('restricted content')) {
    return isUrdu
        ? 'پیغام میں ممنوع مواد ہے۔'
        : 'That message contains restricted content.';
  }
  if (text.contains('ns063') || text.contains('link is not allowed')) {
    return isUrdu
        ? 'یہ لنک اجازت نہیں۔'
        : 'That link is not allowed.';
  }
  if (text.contains('ns060') || text.contains('temporarily disabled')) {
    return isUrdu
        ? 'یہ عمل عارضی طور پر بند ہے۔'
        : 'This action is temporarily disabled.';
  }
  return isUrdu ? 'کارروائی ناکام رہی۔' : 'Action failed.';
}
