import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('register deliver dedupe and cleanup invalid tokens', () async {
    final inbox = FakeStudentNotificationInboxRepository(seed: const []);
    final push = FakePushDeliveryRepository(inbox: inbox);

    await push.registerToken(
      userId: 'u1',
      token: 'fake-device-token-01',
    );

    final event = PushEvent(
      eventId: 'evt-1',
      recipientUserId: 'u1',
      category: 'learning',
      title: 'Topic ready',
      body: 'Forces is waiting.',
      deepLinkPath: '/learning',
    );

    final first = await push.deliver(event);
    expect(first.outcome, PushDeliveryOutcome.delivered);
    expect(await inbox.unreadCount(), 1);

    final second = await push.deliver(event);
    expect(second.outcome, PushDeliveryOutcome.duplicated);
    expect(await inbox.unreadCount(), 1);

    await push.invalidateToken('fake-device-token-01');
    expect(await push.cleanupInvalidTokens(), 1);
    expect(await push.listTokens(userId: 'u1'), isEmpty);

    final third = await push.deliver(
      PushEvent(
        eventId: 'evt-2',
        recipientUserId: 'u1',
        category: 'marks',
        title: 'Marks published',
        body: 'Math 92%',
        deepLinkPath: '/flex/marks',
      ),
    );
    expect(third.outcome, PushDeliveryOutcome.noActiveToken);
    expect(third.lockScreenPreview, 'You have a new Nano update');
  });
}
