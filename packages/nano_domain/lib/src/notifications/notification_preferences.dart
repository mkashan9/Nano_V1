/// NOT-02 quiet hours, category mute, and digest preferences.

class NotificationPreferences {
  const NotificationPreferences({
    this.quietHoursEnabled = false,
    this.quietStartHour = 21,
    this.quietEndHour = 7,
    this.mutedCategories = const {},
    this.digestEnabled = true,
  });

  final bool quietHoursEnabled;

  /// Local hour 0–23 when quiet hours begin (inclusive).
  final int quietStartHour;

  /// Local hour 0–23 when quiet hours end (exclusive).
  final int quietEndHour;
  final Set<String> mutedCategories;
  final bool digestEnabled;

  static const defaults = NotificationPreferences();

  NotificationPreferences copyWith({
    bool? quietHoursEnabled,
    int? quietStartHour,
    int? quietEndHour,
    Set<String>? mutedCategories,
    bool? digestEnabled,
  }) {
    return NotificationPreferences(
      quietHoursEnabled: quietHoursEnabled ?? this.quietHoursEnabled,
      quietStartHour: quietStartHour ?? this.quietStartHour,
      quietEndHour: quietEndHour ?? this.quietEndHour,
      mutedCategories: mutedCategories ?? this.mutedCategories,
      digestEnabled: digestEnabled ?? this.digestEnabled,
    );
  }

  NotificationPreferences withCategoryMuted(String category, bool muted) {
    final next = {...mutedCategories};
    final key = category.trim().toLowerCase();
    if (muted) {
      next.add(key);
    } else {
      next.remove(key);
    }
    return copyWith(mutedCategories: next);
  }

  factory NotificationPreferences.fromJson(Map<String, dynamic> json) {
    final muted = json['muted_categories'];
    return NotificationPreferences(
      quietHoursEnabled: json['quiet_hours_enabled'] as bool? ?? false,
      quietStartHour: (json['quiet_start_hour'] as num?)?.toInt() ?? 21,
      quietEndHour: (json['quiet_end_hour'] as num?)?.toInt() ?? 7,
      mutedCategories: muted is List
          ? {for (final item in muted) '$item'.trim().toLowerCase()}
          : const {},
      digestEnabled: json['digest_enabled'] as bool? ?? true,
    );
  }
}

enum NotificationDeliveryAction {
  deliverNow,
  suppressMuted,
  holdForDigest,
}

class NotificationDeliveryDecision {
  const NotificationDeliveryDecision({
    required this.action,
    required this.mandatory,
  });

  final NotificationDeliveryAction action;
  final bool mandatory;
}

/// Client-side preference gates. Server remains authoritative when live.
abstract final class NotificationPreferencePolicy {
  static const mandatoryCategories = <String>{'account', 'security'};

  static const controllableCategories = <String>{
    'learning',
    'gamification',
    'school',
    'community',
    'games',
    'marks',
  };

  static bool isMandatory(String category) =>
      mandatoryCategories.contains(category.trim().toLowerCase());

  static bool canMute(String category) => !isMandatory(category);

  /// Quiet window that can wrap midnight (e.g. 21 → 7).
  static bool isInQuietHours(
    NotificationPreferences prefs,
    DateTime localNow,
  ) {
    if (!prefs.quietHoursEnabled) return false;
    final hour = localNow.hour;
    final start = prefs.quietStartHour.clamp(0, 23);
    final end = prefs.quietEndHour.clamp(0, 23);
    if (start == end) return true;
    if (start < end) {
      return hour >= start && hour < end;
    }
    return hour >= start || hour < end;
  }

  static NotificationDeliveryDecision decide({
    required NotificationPreferences prefs,
    required String category,
    required DateTime localNow,
  }) {
    final cat = category.trim().toLowerCase();
    final mandatory = isMandatory(cat);

    if (!mandatory && prefs.mutedCategories.contains(cat)) {
      return const NotificationDeliveryDecision(
        action: NotificationDeliveryAction.suppressMuted,
        mandatory: false,
      );
    }

    if (!mandatory &&
        isInQuietHours(prefs, localNow) &&
        prefs.digestEnabled) {
      return NotificationDeliveryDecision(
        action: NotificationDeliveryAction.holdForDigest,
        mandatory: mandatory,
      );
    }

    // Quiet hours without digest still allow in-app delivery (no OS interrupt
    // in a live push path); fake path treats this as deliverNow.
    return NotificationDeliveryDecision(
      action: NotificationDeliveryAction.deliverNow,
      mandatory: mandatory,
    );
  }
}
