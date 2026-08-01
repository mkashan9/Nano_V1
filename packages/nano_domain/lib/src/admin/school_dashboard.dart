import 'platform_dashboard.dart';

/// SCH-01 school-admin overview — tenant metrics + branding snapshot.
class SchoolDashboard {
  const SchoolDashboard({
    required this.schoolId,
    required this.code,
    required this.name,
    required this.displayName,
    required this.status,
    required this.learnerCount,
    required this.staffCount,
    required this.teacherCount,
    required this.classCount,
    required this.setup,
    this.logoUrl = '',
    this.bannerUrl = '',
    this.addressLine = '',
    this.contactEmail = '',
    this.contactPhone = '',
    this.primaryColor = '#2F7BFF',
    this.secondaryColor = '#1B4F9C',
    this.academicYearLabel = '',
  });

  final String schoolId;
  final String code;
  final String name;
  final String displayName;
  final String status;
  final String logoUrl;
  final String bannerUrl;
  final String addressLine;
  final String contactEmail;
  final String contactPhone;
  final String primaryColor;
  final String secondaryColor;
  final String academicYearLabel;
  final int learnerCount;
  final int staffCount;
  final int teacherCount;
  final int classCount;
  final SchoolSetupProgress setup;

  int get setupStepsDone => [
        setup.hasAdmin,
        setup.brandingReady,
        setup.contactReady,
        setup.academicYearReady,
      ].where((step) => step).length;

  factory SchoolDashboard.fromJson(Map<String, dynamic> json) {
    // School brand/ops fields are allowed; learner PII keys are not.
    // PlatformDashboard forbids display_name (learner-facing); school brand uses it.
    final probe = Map<String, dynamic>.from(json)
      ..remove('display_name')
      ..remove('contact_email')
      ..remove('contact_phone')
      ..remove('address_line')
      ..remove('logo_url')
      ..remove('banner_url');
    if (!PlatformDashboard.isPrivacySafePayload(probe)) {
      throw StateError('School dashboard failed privacy review.');
    }
    return SchoolDashboard(
      schoolId: json['school_id'] as String? ?? '',
      code: json['code'] as String? ?? '',
      name: json['name'] as String? ?? '',
      displayName: json['display_name'] as String? ??
          (json['name'] as String? ?? ''),
      status: json['status'] as String? ?? 'active',
      logoUrl: json['logo_url'] as String? ?? '',
      bannerUrl: json['banner_url'] as String? ?? '',
      addressLine: json['address_line'] as String? ?? '',
      contactEmail: json['contact_email'] as String? ?? '',
      contactPhone: json['contact_phone'] as String? ?? '',
      primaryColor: json['primary_color'] as String? ?? '#2F7BFF',
      secondaryColor: json['secondary_color'] as String? ?? '#1B4F9C',
      academicYearLabel: json['academic_year_label'] as String? ?? '',
      learnerCount: (json['learner_count'] as num?)?.toInt() ?? 0,
      staffCount: (json['staff_count'] as num?)?.toInt() ?? 0,
      teacherCount: (json['teacher_count'] as num?)?.toInt() ?? 0,
      classCount: (json['class_count'] as num?)?.toInt() ?? 0,
      setup: SchoolSetupProgress.fromJson(
        json['setup'] is Map
            ? Map<String, dynamic>.from(json['setup'] as Map)
            : const {},
      ),
    );
  }
}

class SchoolSetupProgress {
  const SchoolSetupProgress({
    required this.hasAdmin,
    required this.brandingReady,
    required this.contactReady,
    required this.academicYearReady,
    required this.setupCompleted,
  });

  final bool hasAdmin;
  final bool brandingReady;
  final bool contactReady;
  final bool academicYearReady;
  final bool setupCompleted;

  factory SchoolSetupProgress.fromJson(Map<String, dynamic> json) {
    return SchoolSetupProgress(
      hasAdmin: json['has_admin'] as bool? ?? false,
      brandingReady: json['branding_ready'] as bool? ?? false,
      contactReady: json['contact_ready'] as bool? ?? false,
      academicYearReady: json['academic_year_ready'] as bool? ?? false,
      setupCompleted: json['setup_completed'] as bool? ?? false,
    );
  }
}

/// Hex brand color gate mirrored server-side.
abstract final class SchoolBrandColorRules {
  static final _hex = RegExp(r'^#[0-9A-Fa-f]{6}$');

  static bool isValid(String? value) =>
      value != null && _hex.hasMatch(value.trim());
}
