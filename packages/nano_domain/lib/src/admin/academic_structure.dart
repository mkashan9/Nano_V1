/// SCH-02 school academic structure snapshot.
class AcademicStructure {
  const AcademicStructure({
    required this.schoolId,
    required this.gradeLevels,
    required this.classes,
    required this.sections,
    required this.subjects,
    required this.classSubjects,
    this.mappingIssues = const [],
  });

  final String schoolId;
  final List<GradeLevelRow> gradeLevels;
  final List<SchoolClassRow> classes;
  final List<SectionRow> sections;
  final List<SchoolSubjectRow> subjects;
  final List<ClassSubjectRow> classSubjects;
  final List<MappingIssue> mappingIssues;

  List<GradeLevelRow> get activeGrades =>
      gradeLevels.where((g) => g.isActive).toList(growable: false);

  List<SchoolClassRow> get activeClasses =>
      classes.where((c) => c.isActive).toList(growable: false);

  factory AcademicStructure.fromJson(Map<String, dynamic> json) {
    return AcademicStructure(
      schoolId: json['school_id'] as String? ?? '',
      gradeLevels: _list(json['grade_levels'], GradeLevelRow.fromJson),
      classes: _list(json['classes'], SchoolClassRow.fromJson),
      sections: _list(json['sections'], SectionRow.fromJson),
      subjects: _list(json['subjects'], SchoolSubjectRow.fromJson),
      classSubjects: _list(json['class_subjects'], ClassSubjectRow.fromJson),
      mappingIssues: _list(json['mapping_issues'], MappingIssue.fromJson),
    );
  }

  static List<T> _list<T>(
    Object? raw,
    T Function(Map<String, dynamic>) parse,
  ) {
    if (raw is! List) return const [];
    return [
      for (final item in raw)
        if (item is Map) parse(Map<String, dynamic>.from(item)),
    ];
  }
}

class GradeLevelRow {
  const GradeLevelRow({
    required this.id,
    required this.name,
    required this.sortOrder,
    required this.status,
  });

  final String id;
  final String name;
  final int sortOrder;
  final String status;

  bool get isActive => status == 'active';

  factory GradeLevelRow.fromJson(Map<String, dynamic> json) {
    return GradeLevelRow(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      status: json['status'] as String? ?? 'active',
    );
  }
}

class SchoolClassRow {
  const SchoolClassRow({
    required this.id,
    required this.gradeLevelId,
    required this.name,
    required this.status,
  });

  final String id;
  final String gradeLevelId;
  final String name;
  final String status;

  bool get isActive => status == 'active';

  factory SchoolClassRow.fromJson(Map<String, dynamic> json) {
    return SchoolClassRow(
      id: json['id'] as String? ?? '',
      gradeLevelId: json['grade_level_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class SectionRow {
  const SectionRow({
    required this.id,
    required this.classId,
    required this.name,
    required this.status,
  });

  final String id;
  final String classId;
  final String name;
  final String status;

  bool get isActive => status == 'active';

  factory SectionRow.fromJson(Map<String, dynamic> json) {
    return SectionRow(
      id: json['id'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class SchoolSubjectRow {
  const SchoolSubjectRow({
    required this.id,
    required this.name,
    required this.code,
    required this.status,
    this.learningSubjectId,
  });

  final String id;
  final String name;
  final String code;
  final String status;
  final String? learningSubjectId;

  bool get isActive => status == 'active';

  factory SchoolSubjectRow.fromJson(Map<String, dynamic> json) {
    return SchoolSubjectRow(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      code: json['code'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
      learningSubjectId: json['learning_subject_id'] as String?,
    );
  }
}

class ClassSubjectRow {
  const ClassSubjectRow({
    required this.id,
    required this.classId,
    required this.schoolSubjectId,
    required this.status,
    this.sectionId,
  });

  final String id;
  final String classId;
  final String? sectionId;
  final String schoolSubjectId;
  final String status;

  bool get isActive => status == 'active';

  factory ClassSubjectRow.fromJson(Map<String, dynamic> json) {
    return ClassSubjectRow(
      id: json['id'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      sectionId: json['section_id'] as String?,
      schoolSubjectId: json['school_subject_id'] as String? ?? '',
      status: json['status'] as String? ?? 'active',
    );
  }
}

class MappingIssue {
  const MappingIssue({
    required this.kind,
    required this.classId,
    required this.className,
  });

  final String kind;
  final String classId;
  final String className;

  factory MappingIssue.fromJson(Map<String, dynamic> json) {
    return MappingIssue(
      kind: json['kind'] as String? ?? '',
      classId: json['class_id'] as String? ?? '',
      className: json['class_name'] as String? ?? '',
    );
  }
}

/// Soft-archive kinds accepted by archive_academic_structure.
abstract final class AcademicStructureKind {
  static const gradeLevel = 'grade_level';
  static const classUnit = 'class';
  static const section = 'section';
  static const schoolSubject = 'school_subject';
  static const classSubject = 'class_subject';
}
