import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('mute suppresses and quiet hours hold then flush digest', () async {
    final inbox = FakeStudentNotificationInboxRepository(seed: const []);
    final push = FakePushDeliveryRepository(
      inbox: inbox,
      preferences: const NotificationPreferences(
        quietHoursEnabled: true,
        quietStartHour: 21,
        quietEndHour: 7,
        digestEnabled: true,
        mutedCategories: {'game'},
      ),
      clock: () => DateTime.utc(2026, 8, 3, 22),
    );
    await push.registerToken(userId: 'u1', token: 'fake-device-token-01');

    final muted = await push.deliver(
      PushEvent(
        eventId: 'evt-game',
        recipientUserId: 'u1',
        category: 'game',
        title: 'Challenge',
        body: 'A friend challenged you',
      ),
    );
    expect(muted.outcome, PushDeliveryOutcome.suppressedMuted);
    expect(await inbox.unreadCount(), 0);

    final held = await push.deliver(
      PushEvent(
        eventId: 'evt-learn',
        recipientUserId: 'u1',
        category: 'learning',
        title: 'Topic ready',
        body: 'Forces is waiting.',
        deepLinkPath: '/learning',
      ),
    );
    expect(held.outcome, PushDeliveryOutcome.heldForDigest);
    expect(await inbox.unreadCount(), 0);

    final flushed = await push.flushDigest(userId: 'u1');
    expect(flushed?.outcome, PushDeliveryOutcome.delivered);
    expect(await inbox.unreadCount(), 1);
    expect((await inbox.listInbox()).first.title, 'Notification digest');
  });

  test('preferences repo strips mandatory mutes', () async {
    final repo = FakeNotificationPreferencesRepository();
    final saved = await repo.save(
      userId: 'u1',
      preferences: NotificationPreferences.defaults.copyWith(
        mutedCategories: {'account', 'learning'},
      ),
    );
    expect(saved.mutedCategories, {'learning'});
  });
}
