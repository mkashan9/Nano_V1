/// PAR-01 weekly parent guidance — published, child-safe copy only.

class ParentGuidanceCard {
  const ParentGuidanceCard({
    required this.id,
    required this.weekKey,
    required this.title,
    required this.body,
    required this.publishedAt,
    this.activityTips = const [],
    this.childDisplayName,
  });

  final String id;
  final String weekKey;
  final String title;
  final String body;
  final DateTime publishedAt;
  final List<String> activityTips;
  final String? childDisplayName;

  factory ParentGuidanceCard.fromJson(Map<String, dynamic> json) {
    final tips = json['activity_tips'];
    return ParentGuidanceCard(
      id: json['id'] as String? ?? '',
      weekKey: json['week_key'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      publishedAt: DateTime.tryParse('${json['published_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      activityTips: tips is List
          ? [for (final tip in tips) '$tip']
          : const [],
      childDisplayName: json['child_display_name'] as String?,
    );
  }
}

class GuardianChildLink {
  const GuardianChildLink({
    required this.guardianId,
    required this.childUserId,
    required this.childDisplayName,
  });

  final String guardianId;
  final String childUserId;
  final String childDisplayName;
}

/// Fields that must never appear on a parent guidance surface.
abstract final class ParentGuidanceSafety {
  static const forbiddenFieldNames = <String>{
    'email',
    'phone',
    'draft_marks',
    'private_teacher_notes',
    'payment',
    'device_sessions',
    'guardian_contact',
  };

  static bool mapLooksSafe(Map<String, dynamic> json) {
    for (final key in json.keys) {
      if (forbiddenFieldNames.contains(key)) return false;
    }
    return true;
  }
}

abstract final class GuardianAccessPolicy {
  static bool canViewChild({
    required String guardianId,
    required String childUserId,
    required Iterable<GuardianChildLink> links,
  }) {
    return links.any(
      (link) =>
          link.guardianId == guardianId && link.childUserId == childUserId,
    );
  }

  static List<GuardianChildLink> childrenFor(
    String guardianId,
    Iterable<GuardianChildLink> links,
  ) {
    return [
      for (final link in links)
        if (link.guardianId == guardianId) link,
    ];
  }
}
