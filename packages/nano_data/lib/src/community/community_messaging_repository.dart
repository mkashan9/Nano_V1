import 'dart:typed_data';

import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// COM-04/05 community text + media messages.
abstract class CommunityMessagingRepository {
  Future<List<CommunityMessage>> listMessages(String communityId);

  Future<CommunityMessage> sendMessage({
    required String communityId,
    required String body,
    String? parentMessageId,
    List<String> mentionUserIds = const [],
    List<String> attachmentIds = const [],
  });

  Future<CommunityMessage> toggleReaction({
    required String messageId,
    required String emoji,
  });

  Future<CommunityMessageAttachment> prepareMediaUpload({
    required String communityId,
    required CommunityMediaKind kind,
    String? contentType,
    int? byteSize,
    String? originalFilename,
    int? durationMs,
  });

  Future<void> uploadMediaBytes({
    required String bucket,
    required String path,
    required List<int> bytes,
    String? contentType,
  });

  Future<String?> signedMediaUrl(CommunityMessageAttachment attachment);
}

class FakeCommunityMessagingRepository implements CommunityMessagingRepository {
  FakeCommunityMessagingRepository({
    Map<String, List<CommunityMessage>>? messages,
  }) : _messages = {
          'a1000000-0000-4000-8000-000000000001': [
            CommunityMessage(
              id: 'm-seed-1',
              communityId: 'a1000000-0000-4000-8000-000000000001',
              authorId: 'u-owner',
              authorDisplayName: 'Ayesha',
              body: 'Welcome to Study Circle — ask anything.',
              createdAt: DateTime.utc(2026, 8, 1, 10),
              reactions: const [
                MessageReactionSummary(emoji: '👍', count: 2),
              ],
            ),
            CommunityMessage(
              id: 'm-seed-2',
              communityId: 'a1000000-0000-4000-8000-000000000001',
              authorId: 'u-friend',
              authorDisplayName: 'Bilal',
              body: 'Thanks! Happy to help with maths tips.',
              parentMessageId: 'm-seed-1',
              createdAt: DateTime.utc(2026, 8, 1, 10, 5),
            ),
            CommunityMessage(
              id: 'm-seed-3',
              communityId: 'a1000000-0000-4000-8000-000000000001',
              authorId: 'u-owner',
              authorDisplayName: 'Ayesha',
              body: 'Lab photo from today',
              createdAt: DateTime.utc(2026, 8, 1, 11),
              attachments: const [
                CommunityMessageAttachment(
                  id: 'a-seed-photo',
                  communityId: 'a1000000-0000-4000-8000-000000000001',
                  messageId: 'm-seed-3',
                  kind: CommunityMediaKind.photo,
                  storageBucket: 'community-media',
                  storagePath:
                      'a1000000-0000-4000-8000-000000000001/u-owner/a-seed-photo.jpg',
                  contentType: 'image/jpeg',
                  originalFilename: 'lab.jpg',
                ),
              ],
            ),
            CommunityMessage(
              id: 'm-seed-4',
              communityId: 'a1000000-0000-4000-8000-000000000001',
              authorId: 'u-friend',
              authorDisplayName: 'Bilal',
              body: '',
              createdAt: DateTime.utc(2026, 8, 1, 11, 5),
              attachments: const [
                CommunityMessageAttachment(
                  id: 'a-seed-voice',
                  communityId: 'a1000000-0000-4000-8000-000000000001',
                  messageId: 'm-seed-4',
                  kind: CommunityMediaKind.voice,
                  storageBucket: 'community-media',
                  storagePath:
                      'a1000000-0000-4000-8000-000000000001/u-friend/a-seed-voice.m4a',
                  contentType: 'audio/mp4',
                  durationMs: 4200,
                  originalFilename: 'note.m4a',
                ),
              ],
            ),
          ],
          ...?messages,
        };

  final Map<String, List<CommunityMessage>> _messages;
  final Map<String, CommunityMessageAttachment> _pending = {};
  var alwaysFail = false;
  var _seq = 0;
  var _attachSeq = 0;

  @override
  Future<List<CommunityMessage>> listMessages(String communityId) async {
    if (alwaysFail) throw StateError('Messages unavailable');
    return List.unmodifiable(_messages[communityId] ?? const []);
  }

  @override
  Future<CommunityMessage> sendMessage({
    required String communityId,
    required String body,
    String? parentMessageId,
    List<String> mentionUserIds = const [],
    List<String> attachmentIds = const [],
  }) async {
    if (alwaysFail) throw StateError('Send failed');
    final trimmed = body.trim();
    final attachments = <CommunityMessageAttachment>[
      for (final id in attachmentIds)
        if (_pending[id] != null) _pending[id]!,
    ];
    if (trimmed.isEmpty && attachments.isEmpty) {
      throw StateError('Message required');
    }
    _seq += 1;
    final messageId = 'm-local-$_seq';
    final linked = [
      for (final a in attachments)
        CommunityMessageAttachment(
          id: a.id,
          communityId: a.communityId,
          messageId: messageId,
          kind: a.kind,
          storageBucket: a.storageBucket,
          storagePath: a.storagePath,
          contentType: a.contentType,
          byteSize: a.byteSize,
          durationMs: a.durationMs,
          originalFilename: a.originalFilename,
          status: 'ready',
        ),
    ];
    for (final id in attachmentIds) {
      _pending.remove(id);
    }
    final message = CommunityMessage(
      id: messageId,
      communityId: communityId,
      authorId: 'self',
      authorDisplayName: 'You',
      body: trimmed,
      parentMessageId: parentMessageId,
      createdAt: DateTime.now().toUtc(),
      isSelf: true,
      mentionUserIds: List.unmodifiable(mentionUserIds),
      attachments: linked,
    );
    final list = [...(_messages[communityId] ?? const <CommunityMessage>[])];
    list.add(message);
    _messages[communityId] = list;
    return message;
  }

  @override
  Future<CommunityMessage> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    if (alwaysFail) throw StateError('Reaction failed');
    for (final entry in _messages.entries) {
      final list = [...entry.value];
      final index = list.indexWhere((m) => m.id == messageId);
      if (index < 0) continue;
      final current = list[index];
      final reactions = [...current.reactions];
      final ri = reactions.indexWhere((r) => r.emoji == emoji);
      if (ri >= 0) {
        final existing = reactions[ri];
        if (existing.reactedByMe) {
          final nextCount = existing.count - 1;
          if (nextCount <= 0) {
            reactions.removeAt(ri);
          } else {
            reactions[ri] = MessageReactionSummary(
              emoji: emoji,
              count: nextCount,
            );
          }
        } else {
          reactions[ri] = MessageReactionSummary(
            emoji: emoji,
            count: existing.count + 1,
            reactedByMe: true,
          );
        }
      } else {
        reactions.add(
          MessageReactionSummary(emoji: emoji, count: 1, reactedByMe: true),
        );
      }
      final updated = CommunityMessage(
        id: current.id,
        communityId: current.communityId,
        authorId: current.authorId,
        authorDisplayName: current.authorDisplayName,
        body: current.body,
        parentMessageId: current.parentMessageId,
        createdAt: current.createdAt,
        isSelf: current.isSelf,
        mentionUserIds: current.mentionUserIds,
        reactions: reactions,
        attachments: current.attachments,
      );
      list[index] = updated;
      _messages[entry.key] = list;
      return updated;
    }
    throw StateError('Message not found');
  }

  @override
  Future<CommunityMessageAttachment> prepareMediaUpload({
    required String communityId,
    required CommunityMediaKind kind,
    String? contentType,
    int? byteSize,
    String? originalFilename,
    int? durationMs,
  }) async {
    if (alwaysFail) throw StateError('Upload prepare failed');
    _attachSeq += 1;
    final id = 'a-local-$_attachSeq';
    final attachment = CommunityMessageAttachment(
      id: id,
      communityId: communityId,
      kind: kind,
      storageBucket: 'community-media',
      storagePath: '$communityId/self/$id.bin',
      contentType: contentType,
      byteSize: byteSize,
      durationMs: durationMs,
      originalFilename: originalFilename ?? '${kind.wire}-$_attachSeq',
      status: 'pending',
    );
    _pending[id] = attachment;
    return attachment;
  }

  @override
  Future<void> uploadMediaBytes({
    required String bucket,
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    if (alwaysFail) throw StateError('Upload failed');
  }

  @override
  Future<String?> signedMediaUrl(CommunityMessageAttachment attachment) async {
    if (alwaysFail) throw StateError('Sign failed');
    return 'fake://${attachment.storageBucket}/${attachment.storagePath}';
  }
}

class SupabaseCommunityMessagingRepository
    implements CommunityMessagingRepository {
  SupabaseCommunityMessagingRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<CommunityMessage>> listMessages(String communityId) async {
    final raw = await _client.rpc(
      'list_community_messages',
      params: {'p_community_id': communityId},
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        CommunityMessage.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<CommunityMessage> sendMessage({
    required String communityId,
    required String body,
    String? parentMessageId,
    List<String> mentionUserIds = const [],
    List<String> attachmentIds = const [],
  }) async {
    final raw = await _client.rpc(
      'send_community_message',
      params: {
        'p_community_id': communityId,
        'p_body': body,
        'p_parent_message_id': parentMessageId,
        'p_mention_ids': mentionUserIds.isEmpty ? null : mentionUserIds,
        'p_attachment_ids': attachmentIds.isEmpty ? null : attachmentIds,
      },
    );
    if (raw is! Map) throw StateError('Send failed');
    return CommunityMessage.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<CommunityMessage> toggleReaction({
    required String messageId,
    required String emoji,
  }) async {
    final raw = await _client.rpc(
      'toggle_message_reaction',
      params: {
        'p_message_id': messageId,
        'p_emoji': emoji,
      },
    );
    if (raw is! Map) throw StateError('Reaction failed');
    return CommunityMessage.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<CommunityMessageAttachment> prepareMediaUpload({
    required String communityId,
    required CommunityMediaKind kind,
    String? contentType,
    int? byteSize,
    String? originalFilename,
    int? durationMs,
  }) async {
    final raw = await _client.rpc(
      'prepare_community_media_upload',
      params: {
        'p_community_id': communityId,
        'p_kind': kind.wire,
        'p_content_type': contentType,
        'p_byte_size': byteSize,
        'p_original_filename': originalFilename,
        'p_duration_ms': durationMs,
      },
    );
    if (raw is! Map) throw StateError('Upload prepare failed');
    return CommunityMessageAttachment.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<void> uploadMediaBytes({
    required String bucket,
    required String path,
    required List<int> bytes,
    String? contentType,
  }) async {
    await _client.storage.from(bucket).uploadBinary(
          path,
          Uint8List.fromList(bytes),
          fileOptions: FileOptions(
            contentType: contentType,
            upsert: true,
          ),
        );
  }

  @override
  Future<String?> signedMediaUrl(CommunityMessageAttachment attachment) async {
    return _client.storage
        .from(attachment.storageBucket)
        .createSignedUrl(attachment.storagePath, 3600);
  }
}
