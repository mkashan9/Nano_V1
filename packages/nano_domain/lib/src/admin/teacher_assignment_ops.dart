/// SCH-05 school-admin teacher assignment matrix models.
class TeacherAssignmentMatrix {
  const TeacherAssignmentMatrix({
    required this.schoolId,
    required this.assignments,
    required this.teachers,
    required this.classes,
    required this.sections,
    required this.subjects,
    required this.uncovered,
    required this.conflicts,
    required this.workload,
  });

  final String schoolId;
  final List<TeacherAssignmentRow> assignments;
  final List<AssignmentTeacherOption> teachers;
  final List<AssignmentClassOption> classes;
  final List<AssignmentSectionOption> sections;
  final List<AssignmentSubjectOption> subjects;
  final List<UncoveredClassSubject> uncovered;
  final List<AssignmentConflict> conflicts;
  final List<TeacherWorkload> workload;

  List<TeacherAssignmentRow> get activeAssignments => [
        for (final row in assignments)
          if (row.isActive) row,
      ];

  factory TeacherAssignmentMatrix.fromJson(Map<String, dynamic> json) {
    List<T> mapList<T>(
      String key,
      T Function(Map<String, dynamic>) map,
    ) {
      final raw = json[key];
      if (raw is! List) return const [];
      return [
        for (final row in raw.whereType<Map>())
          map(Map<String, dynamic>.from(row)),
      ];
    }

    return TeacherAssignmentMatrix(
      schoolId: json['school_id'] as String? ?? '',
      assignments: mapList('assignments', TeacherAssignmentRow.fromJson),
      teachers: mapList('teachers', AssignmentTeacherOption.fromJson),
      classes: mapList('classes', AssignmentClassOption.fromJson),
      sections: mapList('sections', AssignmentSectionOption.fromJson),
      subjects: mapList('subjects', AssignmentSubjectOption.fromJson),
      uncovered: mapList('uncovered', UncoveredClassSubject.fromJson),
      conflicts: mapList('conflicts', AssignmentConflict.fromJson),
      workload: mapList('workload', TeacherWorkload.fromJson),
    );
  }
}

class TeacherAssignmentRow {
  const TeacherAssignmentRow({
    required this.id,
    required this.teacherUserId,
    required this.teacherName,
    required this.classId,
    required this.sectionId,
    required this.schoolSubjectId,
    required this.classLabel,
    required this.sectionName,
    required this.subjectCode,
    required this.subjectName,
    required this.status,
    required this.startsOn,
    required this.endsOn,
  });

  final String id;
  final String teacherUserId;
  final String teacherName;
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

  bool get isActive => status == 'active';
  bool get isLegacyStub => classId == null || schoolSubjectId == null;

  String get scopeLabel {
    final section = sectionName.trim().isEmpty ? '' : ' / $sectionName';
    return '$classLabel$section · $subjectCode';
  }

  factory TeacherAssignmentRow.fromJson(Map<String, dynamic> json) {
    return TeacherAssignmentRow(
      id: json['id'] as String? ?? '',
      teacherUserId: json['teacher_user_id'] as String? ?? '',
      teacherName: json['teacher_name'] as String? ?? '',
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

class AssignmentTeacherOption {
  const AssignmentTeacherOption({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory AssignmentTeacherOption.fromJson(Map<String, dynamic> json) {
    return AssignmentTeacherOption(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }
}

class AssignmentClassOption {
  const AssignmentClassOption({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory AssignmentClassOption.fromJson(Map<String, dynamic> json) {
    return AssignmentClassOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class AssignmentSectionOption {
  const AssignmentSectionOption({
    required this.id,
    required this.classId,
    required this.name,
  });

  final String id;
  final String classId;
  final String name;

  factory AssignmentSectionOption.fromJson(Map<String, dynamic> json) {
    return AssignmentSectionOption(
      id: json['id'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
    );
  }
}

class AssignmentSubjectOption {
  const AssignmentSubjectOption({
    required this.id,
    required this.name,
    required this.code,
  });

  final String id;
  final String name;
  final String code;

  factory AssignmentSubjectOption.fromJson(Map<String, dynamic> json) {
    return AssignmentSubjectOption(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
    );
  }
}

class UncoveredClassSubject {
  const UncoveredClassSubject({
    required this.classId,
    required this.className,
    required this.sectionId,
    required this.sectionName,
    required this.schoolSubjectId,
    required this.subjectCode,
    required this.subjectName,
  });

  final String classId;
  final String className;
  final String? sectionId;
  final String? sectionName;
  final String schoolSubjectId;
  final String subjectCode;
  final String subjectName;

  String get label {
    final section =
        (sectionName == null || sectionName!.trim().isEmpty) ? '' : ' / $sectionName';
    return '$className$section · $subjectCode';
  }

  factory UncoveredClassSubject.fromJson(Map<String, dynamic> json) {
    return UncoveredClassSubject(
      classId: json['class_id'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
      sectionId: json['section_id'] as String?,
      sectionName: json['section_name'] as String?,
      schoolSubjectId: json['school_subject_id'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      subjectName: json['subject_name'] as String? ?? '',
    );
  }
}

class AssignmentConflict {
  const AssignmentConflict({
    required this.classId,
    required this.sectionId,
    required this.schoolSubjectId,
    required this.classLabel,
    required this.subjectCode,
    required this.teacherCount,
    required this.teacherNames,
  });

  final String? classId;
  final String? sectionId;
  final String? schoolSubjectId;
  final String classLabel;
  final String subjectCode;
  final int teacherCount;
  final String teacherNames;

  String get label => '$classLabel · $subjectCode ($teacherCount)';

  factory AssignmentConflict.fromJson(Map<String, dynamic> json) {
    return AssignmentConflict(
      classId: json['class_id'] as String?,
      sectionId: json['section_id'] as String?,
      schoolSubjectId: json['school_subject_id'] as String?,
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      teacherCount: (json['teacher_count'] as num?)?.toInt() ?? 0,
      teacherNames: json['teacher_names'] as String? ?? '',
    );
  }
}

class TeacherWorkload {
  const TeacherWorkload({
    required this.teacherUserId,
    required this.displayName,
    required this.activeCount,
  });

  final String teacherUserId;
  final String displayName;
  final int activeCount;

  factory TeacherWorkload.fromJson(Map<String, dynamic> json) {
    return TeacherWorkload(
      teacherUserId: json['teacher_user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      activeCount: (json['active_count'] as num?)?.toInt() ?? 0,
    );
  }
}
