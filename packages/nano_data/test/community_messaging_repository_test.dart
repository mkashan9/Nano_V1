import 'package:nano_data/nano_data.dart';
import 'package:test/test.dart';

void main() {
  test('FakeCommunityMessagingRepository lists, sends, reacts', () async {
    final repo = FakeCommunityMessagingRepository();
    final communityId = 'a1000000-0000-4000-8000-000000000001';
    final listed = await repo.listMessages(communityId);
    expect(listed, isNotEmpty);
    expect(listed.first.isReply, isFalse);

    final sent = await repo.sendMessage(
      communityId: communityId,
      body: 'Ping',
      parentMessageId: listed.first.id,
      mentionUserIds: const ['u-friend'],
    );
    expect(sent.isSelf, isTrue);
    expect(sent.isReply, isTrue);
    expect(sent.mentionUserIds, ['u-friend']);

    final reacted = await repo.toggleReaction(
      messageId: sent.id,
      emoji: '👍',
    );
    expect(reacted.reactions.single.reactedByMe, isTrue);

    final toggledOff = await repo.toggleReaction(
      messageId: sent.id,
      emoji: '👍',
    );
    expect(toggledOff.reactions, isEmpty);
  });
}
