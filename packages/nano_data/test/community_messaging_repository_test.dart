import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('FakeCommunityMessagingRepository lists, sends, reacts', () async {
    final repo = FakeCommunityMessagingRepository();
    final communityId = 'a1000000-0000-4000-8000-000000000001';
    final listed = await repo.listMessages(communityId);
    expect(listed, isNotEmpty);
    expect(listed.first.isReply, isFalse);
    expect(listed.any((m) => m.hasMedia), isTrue);

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

  test('FakeCommunityMessagingRepository prepares and sends media', () async {
    final repo = FakeCommunityMessagingRepository();
    final communityId = 'a1000000-0000-4000-8000-000000000001';
    final prepared = await repo.prepareMediaUpload(
      communityId: communityId,
      kind: CommunityMediaKind.voice,
      contentType: 'audio/mp4',
      originalFilename: 'note.m4a',
      durationMs: 2500,
    );
    expect(prepared.status, 'pending');
    await repo.uploadMediaBytes(
      bucket: prepared.storageBucket,
      path: prepared.storagePath,
      bytes: const [1, 2, 3],
      contentType: 'audio/mp4',
    );
    final sent = await repo.sendMessage(
      communityId: communityId,
      body: '',
      attachmentIds: [prepared.id],
    );
    expect(sent.hasMedia, isTrue);
    expect(sent.attachments.single.kind, CommunityMediaKind.voice);
    expect(sent.attachments.single.status, 'ready');
    expect(await repo.signedMediaUrl(sent.attachments.single), startsWith('fake://'));
  });
}
