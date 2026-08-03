import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('CommunityMessage parses replies, mentions, and reactions', () {
    final message = CommunityMessage.fromJson({
      'id': 'm1',
      'community_id': 'c1',
      'author_id': 'u1',
      'author_display_name': 'Ali',
      'body': 'Hello @friend',
      'parent_message_id': 'm0',
      'created_at': '2026-08-01T10:00:00Z',
      'is_self': false,
      'mention_user_ids': ['u2'],
      'reactions': [
        {'emoji': '👍', 'count': 2, 'reacted_by_me': true},
      ],
    });
    expect(message.isReply, isTrue);
    expect(message.mentionUserIds, ['u2']);
    expect(message.reactions.single.reactedByMe, isTrue);
  });
}
