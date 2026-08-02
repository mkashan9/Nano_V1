/// TCH-01 teacher dashboard read model (caller-scoped assignments only).
class TeacherDashboard {
  const TeacherDashboard({
    required this.schoolId,
    required this.schoolCode,
    required this.schoolName,
    required this.teacherId,
    required this.teacherName,
    required this.activeAssignmentCount,
    required this.pendingAttendanceCount,
    required this.draftAssessmentCount,
    required this.unpublishedMarksCount,
    required this.recentClassroomCount,
    required this.assignments,
    this.generatedAt,
  });

  final String schoolId;
  final String schoolCode;
  final String schoolName;
  final String teacherId;
  final String teacherName;
  final int activeAssignmentCount;
  final int pendingAttendanceCount;
  final int draftAssessmentCount;
  final int unpublishedMarksCount;
  final int recentClassroomCount;
  final List<TeacherAssignmentScope> assignments;
  final DateTime? generatedAt;

  int get pendingTotal =>
      pendingAttendanceCount +
      draftAssessmentCount +
      unpublishedMarksCount +
      recentClassroomCount;

  factory TeacherDashboard.fromJson(Map<String, dynamic> json) {
    final assignmentsRaw = json['assignments'];
    return TeacherDashboard(
      schoolId: json['school_id'] as String? ?? '',
      schoolCode: json['school_code'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ?? '',
      activeAssignmentCount:
          (json['active_assignment_count'] as num?)?.toInt() ?? 0,
      pendingAttendanceCount:
          (json['pending_attendance_count'] as num?)?.toInt() ?? 0,
      draftAssessmentCount:
          (json['draft_assessment_count'] as num?)?.toInt() ?? 0,
      unpublishedMarksCount:
          (json['unpublished_marks_count'] as num?)?.toInt() ?? 0,
      recentClassroomCount:
          (json['recent_classroom_count'] as num?)?.toInt() ?? 0,
      assignments: [
        if (assignmentsRaw is List)
          for (final row in assignmentsRaw.whereType<Map>())
            TeacherAssignmentScope.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class TeacherAssignmentScope {
  const TeacherAssignmentScope({
    required this.id,
    required this.classLabel,
    required this.sectionName,
    required this.subjectCode,
    required this.subjectName,
    required this.status,
    this.classId,
    this.sectionId,
    this.schoolSubjectId,
    this.startsOn,
    this.endsOn,
  });

  final String id;
  final String? classId;
  final String? sectionId;
  final String? schoolSubjectId;
  final String classLabel;
  final String sectionName;
  final String subjectCode;
  final String subjectName;
  final String status;
  final String? startsOn;
  final String? endsOn;

  String get scopeLabel {
    final section = sectionName.trim().isEmpty ? '' : ' / $sectionName';
    return '$classLabel$section · $subjectCode';
  }

  factory TeacherAssignmentScope.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentScope(
      id: json['id'] as String? ?? '',
      classId: json['class_id'] as String?,
      sectionId: json['section_id'] as String?,
      schoolSubjectId: json['school_subject_id'] as String?,
      classLabel: json['class_label'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      startsOn: json['starts_on']?.toString(),
      endsOn: json['ends_on']?.toString(),
    );
  }
}
