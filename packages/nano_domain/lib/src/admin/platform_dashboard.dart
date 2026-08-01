/// ADM-01 superadmin platform overview — safe aggregates only.
class PlatformDashboard {
  const PlatformDashboard({
    required this.schoolCount,
    required this.activeSchoolCount,
    required this.learnerCount,
    required this.staffCount,
    required this.suspendedProfileCount,
    required this.openIncidentCount,
    this.schools = const [],
    this.recentAudit = const [],
  });

  final int schoolCount;
  final int activeSchoolCount;
  final int learnerCount;
  final int staffCount;
  final int suspendedProfileCount;
  final int openIncidentCount;
  final List<SchoolDirectoryEntry> schools;
  final List<AuditPreviewEntry> recentAudit;

  factory PlatformDashboard.fromJson(Map<String, dynamic> json) {
    final schoolsRaw = json['schools'];
    final auditRaw = json['recent_audit'];
    return PlatformDashboard(
      schoolCount: (json['school_count'] as num?)?.toInt() ?? 0,
      activeSchoolCount: (json['active_school_count'] as num?)?.toInt() ?? 0,
      learnerCount: (json['learner_count'] as num?)?.toInt() ?? 0,
      staffCount: (json['staff_count'] as num?)?.toInt() ?? 0,
      suspendedProfileCount:
          (json['suspended_profile_count'] as num?)?.toInt() ?? 0,
      openIncidentCount: (json['open_incident_count'] as num?)?.toInt() ?? 0,
      schools: [
        if (schoolsRaw is List)
          for (final row in schoolsRaw.whereType<Map>())
            SchoolDirectoryEntry.fromJson(Map<String, dynamic>.from(row)),
      ],
      recentAudit: [
        if (auditRaw is List)
          for (final row in auditRaw.whereType<Map>())
            AuditPreviewEntry.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }

  /// Rejects payloads that still carry contact or academic PII keys.
  static bool isPrivacySafePayload(Map<String, dynamic> row) {
    const forbidden = {
      'email',
      'guardian',
      'guardian_contact',
      'phone',
      'attendance',
      'marks',
      'latest_mark',
      'payment',
      'display_name',
      'user_id',
      'actor_user_id',
    };
    for (final key in row.keys) {
      if (forbidden.contains(key.toLowerCase())) return false;
    }
    return true;
  }
}

/// Safe school row for directory search — no personal contact fields.
class SchoolDirectoryEntry {
  const SchoolDirectoryEntry({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.learnerCount = 0,
    this.staffCount = 0,
  });

  final String id;
  final String code;
  final String name;
  final String status;
  final int learnerCount;
  final int staffCount;

  factory SchoolDirectoryEntry.fromJson(Map<String, dynamic> json) {
    if (!PlatformDashboard.isPrivacySafePayload(json)) {
      throw StateError('School summary failed privacy review.');
    }
    return SchoolDirectoryEntry(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      learnerCount: (json['learner_count'] as num?)?.toInt() ?? 0,
      staffCount: (json['staff_count'] as num?)?.toInt() ?? 0,
    );
  }

  bool matchesQuery(String query) {
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return true;
    return name.toLowerCase().contains(q) || code.toLowerCase().contains(q);
  }
}

/// Minimized audit line for the platform home — no actor identity.
class AuditPreviewEntry {
  const AuditPreviewEntry({
    required this.action,
    required this.targetType,
    required this.createdAt,
    this.schoolCode,
  });

  final String action;
  final String targetType;
  final DateTime createdAt;
  final String? schoolCode;

  factory AuditPreviewEntry.fromJson(Map<String, dynamic> json) {
    if (!PlatformDashboard.isPrivacySafePayload(json)) {
      throw StateError('Audit preview failed privacy review.');
    }
    return AuditPreviewEntry(
      action: json['action'] as String? ?? 'other',
      targetType: json['target_type'] as String? ?? '',
      createdAt: DateTime.parse(json['created_at'] as String).toUtc(),
      schoolCode: json['school_code'] as String?,
    );
  }
}
