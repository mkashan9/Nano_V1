/// COM-04/05 community messaging models (text + media attachments).

enum CommunityMediaKind {
  voice,
  photo,
  video,
  file;

  static CommunityMediaKind parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'voice':
        return CommunityMediaKind.voice;
      case 'photo':
        return CommunityMediaKind.photo;
      case 'video':
        return CommunityMediaKind.video;
      case 'file':
      default:
        return CommunityMediaKind.file;
    }
  }

  String get wire => name;
}

class CommunityMessageAttachment {
  const CommunityMessageAttachment({
    required this.id,
    required this.communityId,
    required this.kind,
    required this.storageBucket,
    required this.storagePath,
    this.messageId,
    this.contentType,
    this.byteSize,
    this.durationMs,
    this.originalFilename,
    this.status = 'ready',
  });

  final String id;
  final String communityId;
  final String? messageId;
  final CommunityMediaKind kind;
  final String storageBucket;
  final String storagePath;
  final String? contentType;
  final int? byteSize;
  final int? durationMs;
  final String? originalFilename;
  final String status;

  String get displayLabel {
    final name = originalFilename?.trim();
    if (name != null && name.isNotEmpty) return name;
    return switch (kind) {
      CommunityMediaKind.voice => 'Voice message',
      CommunityMediaKind.photo => 'Photo',
      CommunityMediaKind.video => 'Video',
      CommunityMediaKind.file => 'File',
    };
  }

  factory CommunityMessageAttachment.fromJson(Map<String, dynamic> json) {
    return CommunityMessageAttachment(
      id: json['id'] as String? ?? '',
      communityId: json['community_id'] as String? ?? '',
      messageId: json['message_id'] as String?,
      kind: CommunityMediaKind.parse(json['kind'] as String?),
      storageBucket: json['storage_bucket'] as String? ?? 'community-media',
      storagePath: json['storage_path'] as String? ?? '',
      contentType: json['content_type'] as String?,
      byteSize: json['byte_size'] as int?,
      durationMs: json['duration_ms'] as int?,
      originalFilename: json['original_filename'] as String?,
      status: json['status'] as String? ?? 'ready',
    );
  }
}

class MessageReactionSummary {
  const MessageReactionSummary({
    required this.emoji,
    required this.count,
    this.reactedByMe = false,
  });

  final String emoji;
  final int count;
  final bool reactedByMe;

  factory MessageReactionSummary.fromJson(Map<String, dynamic> json) {
    return MessageReactionSummary(
      emoji: json['emoji'] as String? ?? '',
      count: json['count'] as int? ?? 0,
      reactedByMe: json['reacted_by_me'] as bool? ?? false,
    );
  }
}

class CommunityMessage {
  const CommunityMessage({
    required this.id,
    required this.communityId,
    required this.authorId,
    required this.authorDisplayName,
    required this.body,
    this.parentMessageId,
    this.createdAt,
    this.isSelf = false,
    this.mentionUserIds = const [],
    this.reactions = const [],
    this.attachments = const [],
  });

  final String id;
  final String communityId;
  final String authorId;
  final String authorDisplayName;
  final String body;
  final String? parentMessageId;
  final DateTime? createdAt;
  final bool isSelf;
  final List<String> mentionUserIds;
  final List<MessageReactionSummary> reactions;
  final List<CommunityMessageAttachment> attachments;

  bool get isReply => parentMessageId != null && parentMessageId!.isNotEmpty;

  bool get hasMedia => attachments.isNotEmpty;

  factory CommunityMessage.fromJson(Map<String, dynamic> json) {
    final mentionsRaw = json['mention_user_ids'];
    final reactionsRaw = json['reactions'];
    final attachmentsRaw = json['attachments'];
    return CommunityMessage(
      id: json['id'] as String? ?? '',
      communityId: json['community_id'] as String? ?? '',
      authorId: json['author_id'] as String? ?? '',
      authorDisplayName: json['author_display_name'] as String? ?? 'Member',
      body: json['body'] as String? ?? '',
      parentMessageId: json['parent_message_id'] as String?,
      createdAt: _parseTime(json['created_at']),
      isSelf: json['is_self'] as bool? ?? false,
      mentionUserIds: mentionsRaw is List
          ? [
              for (final id in mentionsRaw)
                if (id != null) '$id',
            ]
          : const [],
      reactions: reactionsRaw is List
          ? [
              for (final row in reactionsRaw.whereType<Map>())
                MessageReactionSummary.fromJson(
                  Map<String, dynamic>.from(row),
                ),
            ]
          : const [],
      attachments: attachmentsRaw is List
          ? [
              for (final row in attachmentsRaw.whereType<Map>())
                CommunityMessageAttachment.fromJson(
                  Map<String, dynamic>.from(row),
                ),
            ]
          : const [],
    );
  }
}

DateTime? _parseTime(Object? raw) {
  if (raw is String && raw.isNotEmpty) return DateTime.tryParse(raw);
  return null;
}
