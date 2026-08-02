import '../teacher/teacher_classroom.dart';

export '../teacher/teacher_classroom.dart'
    show ClassroomAttachmentKind, ClassroomItemStatus, TeacherClassroomAttachment;

/// FLX-04 published classroom announcement visible to an enrolled student.
class StudentClassroomItem {
  const StudentClassroomItem({
    required this.id,
    required this.title,
    required this.body,
    required this.status,
    this.attachments = const [],
    this.subjectCode,
    this.classLabel,
    this.publishedAt,
    this.expiresAt,
    this.requiresAcknowledgement = true,
    this.isExpired = false,
    this.acknowledged = false,
    this.acknowledgedAt,
  });

  final String id;
  final String title;
  final String body;
  final ClassroomItemStatus status;
  final List<TeacherClassroomAttachment> attachments;
  final String? subjectCode;
  final String? classLabel;
  final DateTime? publishedAt;
  final DateTime? expiresAt;
  final bool requiresAcknowledgement;
  final bool isExpired;
  final bool acknowledged;
  final DateTime? acknowledgedAt;

  bool get canAcknowledge =>
      requiresAcknowledgement &&
      !isExpired &&
      !acknowledged &&
      status == ClassroomItemStatus.published;

  factory StudentClassroomItem.fromJson(Map<String, dynamic> json) {
    final attachmentsRaw = json['attachments'];
    return StudentClassroomItem(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      status: ClassroomItemStatus.parse(json['status'] as String?),
      attachments: [
        if (attachmentsRaw is List)
          for (final row in attachmentsRaw.whereType<Map>())
            TeacherClassroomAttachment.fromJson(
              Map<String, dynamic>.from(row),
            ),
      ],
      subjectCode: json['subject_code'] as String?,
      classLabel: json['class_label'] as String?,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.tryParse('${json['published_at']}'),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.tryParse('${json['expires_at']}'),
      requiresAcknowledgement:
          json['requires_acknowledgement'] as bool? ?? true,
      isExpired: json['is_expired'] as bool? ?? false,
      acknowledged: json['acknowledged'] as bool? ?? false,
      acknowledgedAt: json['acknowledged_at'] == null
          ? null
          : DateTime.tryParse('${json['acknowledged_at']}'),
    );
  }
}

class StudentClassroomFeed {
  const StudentClassroomFeed({
    required this.items,
    this.generatedAt,
  });

  final List<StudentClassroomItem> items;
  final DateTime? generatedAt;

  int get pendingAckCount =>
      items.where((i) => i.canAcknowledge).length;

  factory StudentClassroomFeed.fromJson(Map<String, dynamic> json) {
    final rows = json['items'];
    return StudentClassroomFeed(
      items: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            StudentClassroomItem.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}
