/// CLS-01 teacher classroom announcement models (draft-focused).
enum ClassroomItemStatus {
  draft,
  published;

  static ClassroomItemStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'published':
        return ClassroomItemStatus.published;
      case 'draft':
      default:
        return ClassroomItemStatus.draft;
    }
  }

  String get wire => name;

  bool get isDraft => this == ClassroomItemStatus.draft;
}

class TeacherClassroomItem {
  const TeacherClassroomItem({
    required this.id,
    required this.schoolId,
    required this.teacherAssignmentId,
    required this.title,
    required this.body,
    required this.status,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String teacherAssignmentId;
  final String title;
  final String body;
  final ClassroomItemStatus status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status.isDraft;

  factory TeacherClassroomItem.fromJson(Map<String, dynamic> json) {
    return TeacherClassroomItem(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      teacherAssignmentId: json['teacher_assignment_id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: ClassroomItemStatus.parse(json['status'] as String?),
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.tryParse('${json['published_at']}'),
      createdAt: json['created_at'] == null
          ? null
          : DateTime.tryParse('${json['created_at']}'),
      updatedAt: json['updated_at'] == null
          ? null
          : DateTime.tryParse('${json['updated_at']}'),
    );
  }
}

class TeacherClassroomList {
  const TeacherClassroomList({
    required this.assignmentId,
    required this.schoolId,
    required this.classLabel,
    required this.subjectCode,
    required this.items,
    this.generatedAt,
  });

  final String assignmentId;
  final String schoolId;
  final String classLabel;
  final String subjectCode;
  final List<TeacherClassroomItem> items;
  final DateTime? generatedAt;

  String get scopeLabel => '$classLabel · $subjectCode';

  factory TeacherClassroomList.fromJson(Map<String, dynamic> json) {
    final rows = json['items'];
    return TeacherClassroomList(
      assignmentId: json['assignment_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      items: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            TeacherClassroomItem.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class TeacherClassroomDraftInput {
  const TeacherClassroomDraftInput({
    required this.title,
    this.body = '',
    this.publishNow = false,
  });

  final String title;
  final String body;
  final bool publishNow;
}
