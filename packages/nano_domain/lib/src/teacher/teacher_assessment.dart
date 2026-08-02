/// MRK-01 assessment creation domain models (draft-focused).
enum AssessmentStatus {
  draft,
  published,
  corrected,
  closed;

  static AssessmentStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'published':
        return AssessmentStatus.published;
      case 'corrected':
        return AssessmentStatus.corrected;
      case 'closed':
        return AssessmentStatus.closed;
      case 'draft':
      default:
        return AssessmentStatus.draft;
    }
  }

  String get wire => name;

  bool get isDraft => this == AssessmentStatus.draft;

  bool get isCorrectable =>
      this == AssessmentStatus.published || this == AssessmentStatus.corrected;

  bool get isClosed => this == AssessmentStatus.closed;
}

class TeacherAssessment {
  const TeacherAssessment({
    required this.id,
    required this.schoolId,
    required this.teacherAssignmentId,
    required this.category,
    required this.name,
    required this.assessmentDate,
    required this.totalMarks,
    required this.status,
    this.weight,
    this.description = '',
    this.resultPeriodId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String teacherAssignmentId;
  final String category;
  final String name;
  final String assessmentDate;
  final double totalMarks;
  final double? weight;
  final String description;
  final AssessmentStatus status;
  final String? resultPeriodId;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status.isDraft;

  bool get isCorrectable => status.isCorrectable;

  factory TeacherAssessment.fromJson(Map<String, dynamic> json) {
    return TeacherAssessment(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      teacherAssignmentId: json['teacher_assignment_id'] as String? ?? '',
      category: json['category'] as String? ?? '',
      name: json['name'] as String? ?? '',
      assessmentDate: '${json['assessment_date'] ?? ''}',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
      weight: (json['weight'] as num?)?.toDouble(),
      description: json['description'] as String? ?? '',
      status: AssessmentStatus.parse(json['status'] as String?),
      resultPeriodId: json['result_period_id'] as String?,
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse('${json['updated_at']}'),
    );
  }
}

class TeacherAssessmentList {
  const TeacherAssessmentList({
    required this.assignmentId,
    required this.schoolId,
    required this.classLabel,
    required this.subjectCode,
    required this.assessments,
    this.generatedAt,
  });

  final String assignmentId;
  final String schoolId;
  final String classLabel;
  final String subjectCode;
  final List<TeacherAssessment> assessments;
  final DateTime? generatedAt;

  String get scopeLabel => '$classLabel · $subjectCode';

  int get draftCount =>
      assessments.where((a) => a.isDraft).length;

  factory TeacherAssessmentList.fromJson(Map<String, dynamic> json) {
    final rows = json['assessments'];
    return TeacherAssessmentList(
      assignmentId: json['assignment_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      assessments: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            TeacherAssessment.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class TeacherAssessmentDraftInput {
  const TeacherAssessmentDraftInput({
    required this.category,
    required this.name,
    required this.assessmentDate,
    required this.totalMarks,
    this.weight,
    this.description = '',
    this.resultPeriodId,
  });

  final String category;
  final String name;
  final String assessmentDate;
  final double totalMarks;
  final double? weight;
  final String description;
  final String? resultPeriodId;
}
