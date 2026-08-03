import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/notifications/presentation/notifications_inbox_page.dart';

void main() {
  testWidgets('simulate push delivers once then dedupes', (tester) async {
    final inbox = FakeStudentNotificationInboxRepository(seed: const []);
    final push = FakePushDeliveryRepository(inbox: inbox);
    await push.registerToken(userId: 'u1', token: 'fake-device-token-01');

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: NotificationsInboxPage(
            repository: inbox,
            pushDelivery: push,
            principal: SessionPrincipal.seniorSchool().copyWith(userId: 'u1'),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Simulate push'));
    await tester.pumpAndSettle();
    expect(find.text('Push: topic ready'), findsOneWidget);
    expect(await inbox.unreadCount(), 1);

    await tester.tap(find.text('Simulate push'));
    await tester.pumpAndSettle();
    expect(await inbox.unreadCount(), 1);
    expect(find.text('Push: topic ready'), findsOneWidget);
  });

  testWidgets('unavailable deep link falls back safely', (tester) async {
    final inbox = FakeStudentNotificationInboxRepository(
      seed: [
        InboxItem(
          id: 'bad',
          category: 'system',
          title: 'Broken link',
          body: 'This path is gone.',
          createdAt: DateTime.utc(2026, 8, 3),
          deepLinkPath: '/not-a-route',
        ),
      ],
    );

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: NotificationsInboxPage(
            repository: inbox,
            principal: SessionPrincipal.seniorSchool(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text('Broken link'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Target unavailable'), findsOneWidget);
  });
}
