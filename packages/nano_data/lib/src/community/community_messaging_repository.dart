import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// COM-04 community text messages, replies, mentions, reactions.
abstract class CommunityMessagingRepository {
  Future<List<CommunityMessage>> listMessages(String communityId);

  Future<CommunityMessage> sendMessage({
    required String communityId,
    required String body,
    String? parentMessageId,
    List<String> mentionUserIds = const [],
  });

  Future<CommunityMessage> toggleReaction({
    required String messageId,
    required String emoji,
  });
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
          ],
          ...?messages,
        };

  final Map<String, List<CommunityMessage>> _messages;
  var alwaysFail = false;
  var _seq = 0;

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
  }) async {
    if (alwaysFail) throw StateError('Send failed');
    final trimmed = body.trim();
    if (trimmed.isEmpty) throw StateError('Message required');
    _seq += 1;
    final message = CommunityMessage(
      id: 'm-local-$_seq',
      communityId: communityId,
      authorId: 'self',
      authorDisplayName: 'You',
      body: trimmed,
      parentMessageId: parentMessageId,
      createdAt: DateTime.now().toUtc(),
      isSelf: true,
      mentionUserIds: List.unmodifiable(mentionUserIds),
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
      );
      list[index] = updated;
      _messages[entry.key] = list;
      return updated;
    }
    throw StateError('Message not found');
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
  }) async {
    final raw = await _client.rpc(
      'send_community_message',
      params: {
        'p_community_id': communityId,
        'p_body': body,
        'p_parent_message_id': parentMessageId,
        'p_mention_ids': mentionUserIds.isEmpty ? null : mentionUserIds,
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
}
