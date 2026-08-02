import 'teacher_dashboard.dart';

/// TCH-02 My Classes list and assignment-scoped roster.
class TeacherMyClasses {
  const TeacherMyClasses({
    required this.schoolId,
    required this.teacherId,
    required this.assignments,
    this.generatedAt,
  });

  final String schoolId;
  final String teacherId;
  final List<TeacherAssignmentScope> assignments;
  final DateTime? generatedAt;

  factory TeacherMyClasses.fromJson(Map<String, dynamic> json) {
    final raw = json['assignments'];
    return TeacherMyClasses(
      schoolId: json['school_id'] as String? ?? '',
      teacherId: json['teacher_id'] as String? ?? '',
      assignments: [
        if (raw is List)
          for (final row in raw.whereType<Map>())
            TeacherAssignmentScope.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class TeacherClassRoster {
  const TeacherClassRoster({
    required this.assignmentId,
    required this.schoolId,
    required this.classLabel,
    required this.sectionName,
    required this.subjectCode,
    required this.subjectName,
    required this.studentCount,
    required this.students,
    this.classId,
    this.sectionId,
    this.generatedAt,
  });

  final String assignmentId;
  final String schoolId;
  final String? classId;
  final String? sectionId;
  final String classLabel;
  final String sectionName;
  final String subjectCode;
  final String subjectName;
  final int studentCount;
  final List<TeacherRosterStudent> students;
  final DateTime? generatedAt;

  String get scopeLabel {
    final section = sectionName.trim().isEmpty ? '' : ' / $sectionName';
    return '$classLabel$section · $subjectCode';
  }

  factory TeacherClassRoster.fromJson(Map<String, dynamic> json) {
    final raw = json['students'];
    return TeacherClassRoster(
      assignmentId: json['assignment_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      classId: json['class_id'] as String?,
      sectionId: json['section_id'] as String?,
      classLabel: json['class_label'] as String? ?? '',
      sectionName: json['section_name'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
      studentCount: (json['student_count'] as num?)?.toInt() ?? 0,
      students: [
        if (raw is List)
          for (final row in raw.whereType<Map>())
            TeacherRosterStudent.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class TeacherRosterStudent {
  const TeacherRosterStudent({
    required this.id,
    required this.displayName,
    required this.enrollmentStatus,
    this.enrolledAt,
  });

  final String id;
  final String displayName;
  final String enrollmentStatus;
  final DateTime? enrolledAt;

  factory TeacherRosterStudent.fromJson(Map<String, dynamic> json) {
    return TeacherRosterStudent(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      enrollmentStatus: json['enrollment_status'] as String? ?? 'active',
      enrolledAt: json['enrolled_at'] == null
          ? null
          : DateTime.tryParse('${json['enrolled_at']}'),
    );
  }
}
