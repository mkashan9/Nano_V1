/// CLS-01/CLS-02/CLS-03 teacher classroom announcement models.
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

enum ClassroomAttachmentKind {
  link,
  file;

  static ClassroomAttachmentKind parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'file':
        return ClassroomAttachmentKind.file;
      case 'link':
      default:
        return ClassroomAttachmentKind.link;
    }
  }

  String get wire => name;
}

class TeacherClassroomAttachment {
  const TeacherClassroomAttachment({
    required this.id,
    required this.classroomItemId,
    required this.kind,
    required this.title,
    this.url,
    this.storageBucket,
    this.storagePath,
    this.contentType,
    this.byteSize,
    this.checksum,
    this.sortOrder = 1,
  });

  final String id;
  final String classroomItemId;
  final ClassroomAttachmentKind kind;
  final String title;
  final String? url;
  final String? storageBucket;
  final String? storagePath;
  final String? contentType;
  final int? byteSize;
  final String? checksum;
  final int sortOrder;

  factory TeacherClassroomAttachment.fromJson(Map<String, dynamic> json) {
    return TeacherClassroomAttachment(
      id: json['id'] as String? ?? '',
      classroomItemId: json['classroom_item_id'] as String? ?? '',
      kind: ClassroomAttachmentKind.parse(json['kind'] as String?),
      title: json['title'] as String? ?? '',
      url: json['url'] as String?,
      storageBucket: json['storage_bucket'] as String?,
      storagePath: json['storage_path'] as String?,
      contentType: json['content_type'] as String?,
      byteSize: (json['byte_size'] as num?)?.toInt(),
      checksum: json['checksum'] as String?,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 1,
    );
  }
}

class TeacherClassroomAttachmentInput {
  const TeacherClassroomAttachmentInput({
    required this.title,
    this.kind = ClassroomAttachmentKind.link,
    this.url,
    this.storageBucket,
    this.storagePath,
    this.contentType,
    this.byteSize,
    this.checksum,
  });

  final ClassroomAttachmentKind kind;
  final String title;
  final String? url;
  final String? storageBucket;
  final String? storagePath;
  final String? contentType;
  final int? byteSize;
  final String? checksum;
}

class TeacherClassroomItem {
  const TeacherClassroomItem({
    required this.id,
    required this.schoolId,
    required this.teacherAssignmentId,
    required this.title,
    required this.body,
    required this.status,
    this.attachments = const [],
    this.scheduledPublishAt,
    this.expiresAt,
    this.requiresAcknowledgement = true,
    this.isExpired = false,
    this.ackCount = 0,
    this.rosterCount = 0,
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
  final List<TeacherClassroomAttachment> attachments;
  final DateTime? scheduledPublishAt;
  final DateTime? expiresAt;
  final bool requiresAcknowledgement;
  final bool isExpired;
  final int ackCount;
  final int rosterCount;
  final DateTime? publishedAt;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  bool get isDraft => status.isDraft;

  bool get isScheduled =>
      isDraft &&
      scheduledPublishAt != null &&
      scheduledPublishAt!.isAfter(DateTime.now().toUtc());

  String get displayStatus {
    if (isExpired) return 'expired';
    if (isScheduled) return 'scheduled';
    return status.wire;
  }

  factory TeacherClassroomItem.fromJson(Map<String, dynamic> json) {
    final attachmentsRaw = json['attachments'];
    return TeacherClassroomItem(
      id: json['id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      teacherAssignmentId: json['teacher_assignment_id'] as String? ?? '',
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
      scheduledPublishAt: json['scheduled_publish_at'] == null
          ? null
          : DateTime.tryParse('${json['scheduled_publish_at']}'),
      expiresAt: json['expires_at'] == null
          ? null
          : DateTime.tryParse('${json['expires_at']}'),
      requiresAcknowledgement:
          json['requires_acknowledgement'] as bool? ?? true,
      isExpired: json['is_expired'] as bool? ?? false,
      ackCount: (json['ack_count'] as num?)?.toInt() ?? 0,
      rosterCount: (json['roster_count'] as num?)?.toInt() ?? 0,
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
    this.scheduledPublishAt,
    this.expiresAt,
    this.requiresAcknowledgement = true,
    this.clearSchedule = false,
    this.clearExpiry = false,
  });

  final String title;
  final String body;
  final bool publishNow;
  final DateTime? scheduledPublishAt;
  final DateTime? expiresAt;
  final bool requiresAcknowledgement;
  final bool clearSchedule;
  final bool clearExpiry;
}
