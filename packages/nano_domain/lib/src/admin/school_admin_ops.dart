import '../tenancy/tenancy_models.dart';

/// ADM-02 school write helpers — codes are immutable after create.
abstract final class SchoolCodeRules {
  static final RegExp pattern = RegExp(r'^[A-Z0-9]{3,16}$');

  static String normalize(String raw) => raw.trim().toUpperCase();

  static bool isValid(String raw) => pattern.hasMatch(normalize(raw));
}

/// Result of creating or updating a school row for admin UI.
class ManagedSchool {
  const ManagedSchool({
    required this.id,
    required this.code,
    required this.name,
    required this.status,
    this.hasSchoolAdmin = false,
    this.learnerCount = 0,
    this.staffCount = 0,
  });

  final String id;
  final String code;
  final String name;
  final SchoolStatus status;
  final bool hasSchoolAdmin;
  final int learnerCount;
  final int staffCount;

  factory ManagedSchool.fromJson(Map<String, dynamic> json) {
    return ManagedSchool(
      id: json['id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: _statusFrom(json['status'] as String? ?? 'active'),
      hasSchoolAdmin: json['has_school_admin'] as bool? ?? false,
      learnerCount: (json['learner_count'] as num?)?.toInt() ?? 0,
      staffCount: (json['staff_count'] as num?)?.toInt() ?? 0,
    );
  }

  static SchoolStatus _statusFrom(String value) => switch (value) {
        'suspended' => SchoolStatus.suspended,
        'archived' => SchoolStatus.archived,
        _ => SchoolStatus.active,
      };
}

extension SchoolStatusWire on SchoolStatus {
  String get wireName => switch (this) {
        SchoolStatus.active => 'active',
        SchoolStatus.suspended => 'suspended',
        SchoolStatus.archived => 'archived',
      };
}
