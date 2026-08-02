/// FBK-01 teacher structured feedback notes (effort / behavior / progress).
enum FeedbackCategory {
  effort,
  behavior,
  progress;

  static FeedbackCategory parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'behavior':
        return FeedbackCategory.behavior;
      case 'progress':
        return FeedbackCategory.progress;
      case 'effort':
      default:
        return FeedbackCategory.effort;
    }
  }

  String get wire => name;

  String get label => switch (this) {
        FeedbackCategory.effort => 'Effort',
        FeedbackCategory.behavior => 'Behavior',
        FeedbackCategory.progress => 'Progress',
      };
}

enum FeedbackNoteStatus {
  draft,
  published;

  static FeedbackNoteStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'published':
        return FeedbackNoteStatus.published;
      case 'draft':
      default:
        return FeedbackNoteStatus.draft;
    }
  }

  String get wire => name;

  bool get isDraft => this == FeedbackNoteStatus.draft;
}

class TeacherFeedbackNote {
  const TeacherFeedbackNote({
    required this.id,
    required this.schoolId,
    required this.teacherAssignmentId,
    required this.studentUserId,
    required this.studentDisplayName,
    required this.category,
    required this.body,
    required this.status,
    this.publishedAt,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String schoolId;
  final String teacherAssignmentId;
  final String studentUserId;
  final String studentDisplayName;
  final FeedbackCategory category;
  final String body;
  final FeedbackNoteStatus status;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status.isDraft;

  factory TeacherFeedbackNote.fromJson(Map<String, dynamic> json) {
    return TeacherFeedbackNote(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      teacherAssignmentId: json['teacher_assignment_id'] as String? ?? '',
      studentUserId: json['student_user_id'] as String? ?? '',
      studentDisplayName: json['student_display_name'] as String? ?? 'Student',
      category: FeedbackCategory.parse(json['category'] as String?),
      body: json['body'] as String? ?? '',
      status: FeedbackNoteStatus.parse(json['status'] as String?),
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

class TeacherFeedbackDraftInput {
  const TeacherFeedbackDraftInput({
    required this.studentUserId,
    required this.category,
    required this.body,
    this.publishNow = false,
  });

  final String studentUserId;
  final FeedbackCategory category;
  final String body;
  final bool publishNow;
}

class TeacherFeedbackList {
  const TeacherFeedbackList({
    required this.assignmentId,
    required this.schoolId,
    required this.classLabel,
    required this.subjectCode,
    required this.notes,
    this.generatedAt,
  });

  final String assignmentId;
  final String schoolId;
  final String classLabel;
  final String subjectCode;
  final List<TeacherFeedbackNote> notes;
  final DateTime? generatedAt;

  String get scopeLabel => '$classLabel · $subjectCode';

  factory TeacherFeedbackList.fromJson(Map<String, dynamic> json) {
    final rows = json['notes'];
    return TeacherFeedbackList(
      assignmentId: json['assignment_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      notes: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            TeacherFeedbackNote.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}
