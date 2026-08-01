import 'platform_dashboard.dart';

/// SCH-07 school-admin operational report snapshot (no learner PII).
class SchoolReportsSummary {
  const SchoolReportsSummary({
    required this.schoolId,
    required this.learnerCount,
    required this.teacherCount,
    required this.staffCount,
    required this.classCount,
    required this.subjectCount,
    required this.classSubjectCount,
    required this.uncoveredClassSubjectCount,
    required this.activeAssignmentCount,
    required this.teachersWithAssignmentCount,
    required this.studentsWithClassCount,
    required this.studentsWithoutClassCount,
    required this.openPeriodCount,
    required this.closedPeriodCount,
    required this.passingPercent,
    required this.attendanceMode,
    required this.reportCardFormat,
    required this.teacherWorkload,
    this.generatedAt,
  });

  final String schoolId;
  final int learnerCount;
  final int teacherCount;
  final int staffCount;
  final int classCount;
  final int subjectCount;
  final int classSubjectCount;
  final int uncoveredClassSubjectCount;
  final int activeAssignmentCount;
  final int teachersWithAssignmentCount;
  final int studentsWithClassCount;
  final int studentsWithoutClassCount;
  final int openPeriodCount;
  final int closedPeriodCount;
  final double passingPercent;
  final String attendanceMode;
  final String reportCardFormat;
  final List<TeacherWorkloadRow> teacherWorkload;
  final DateTime? generatedAt;

  bool get hasCoverageGap => uncoveredClassSubjectCount > 0;

  factory SchoolReportsSummary.fromJson(Map<String, dynamic> json) {
    if (!PlatformDashboard.isPrivacySafePayload(json)) {
      throw StateError('School reports failed privacy review.');
    }
    final workloadRaw = json['teacher_workload'];
    return SchoolReportsSummary(
      schoolId: json['school_id'] as String? ?? '',
      learnerCount: (json['learner_count'] as num?)?.toInt() ?? 0,
      teacherCount: (json['teacher_count'] as num?)?.toInt() ?? 0,
      staffCount: (json['staff_count'] as num?)?.toInt() ?? 0,
      classCount: (json['class_count'] as num?)?.toInt() ?? 0,
      subjectCount: (json['subject_count'] as num?)?.toInt() ?? 0,
      classSubjectCount: (json['class_subject_count'] as num?)?.toInt() ?? 0,
      uncoveredClassSubjectCount:
          (json['uncovered_class_subject_count'] as num?)?.toInt() ?? 0,
      activeAssignmentCount:
          (json['active_assignment_count'] as num?)?.toInt() ?? 0,
      teachersWithAssignmentCount:
          (json['teachers_with_assignment_count'] as num?)?.toInt() ?? 0,
      studentsWithClassCount:
          (json['students_with_class_count'] as num?)?.toInt() ?? 0,
      studentsWithoutClassCount:
          (json['students_without_class_count'] as num?)?.toInt() ?? 0,
      openPeriodCount: (json['open_period_count'] as num?)?.toInt() ?? 0,
      closedPeriodCount: (json['closed_period_count'] as num?)?.toInt() ?? 0,
      passingPercent: (json['passing_percent'] as num?)?.toDouble() ?? 40,
      attendanceMode: json['attendance_mode'] as String? ?? 'daily',
      reportCardFormat: json['report_card_format'] as String? ?? 'both',
      teacherWorkload: [
        if (workloadRaw is List)
          for (final row in workloadRaw.whereType<Map>())
            TeacherWorkloadRow.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class TeacherWorkloadRow {
  const TeacherWorkloadRow({
    required this.displayName,
    required this.activeCount,
  });

  final String displayName;
  final int activeCount;

  factory TeacherWorkloadRow.fromJson(Map<String, dynamic> json) {
    // Staff display names are intentional for school-admin reports (not learner PII).
    return TeacherWorkloadRow(
      displayName: json['display_name'] as String? ?? '',
      activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
    );
  }
}
