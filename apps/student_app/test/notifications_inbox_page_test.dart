import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/notifications/presentation/notifications_inbox_page.dart';

Widget _host(StudentNotificationInboxRepository repository) {
  return NanoLocaleScope(
    locale: NanoAppLocale.en,
    copy: const NanoCopy(NanoAppLocale.en),
    child: MaterialApp(
      theme: NanoTheme.junior(),
      home: NotificationsInboxPage(repository: repository),
    ),
  );
}

void main() {
  testWidgets('lists inbox items and filters unread', (tester) async {
    final repo = FakeStudentNotificationInboxRepository();
    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    expect(find.text('Notifications'), findsOneWidget);
    expect(find.text('New topic unlocked'), findsOneWidget);
    expect(find.text('Assembly note'), findsOneWidget);

    await tester.tap(find.text('Unread'));
    await tester.pumpAndSettle();
    expect(find.text('Assembly note'), findsNothing);
    expect(find.text('New topic unlocked'), findsOneWidget);
  });

  testWidgets('tapping an unread item marks it read', (tester) async {
    final repo = FakeStudentNotificationInboxRepository();
    await tester.pumpWidget(_host(repo));
    await tester.pumpAndSettle();

    await tester.tap(find.text('New topic unlocked'));
    await tester.pumpAndSettle();

    expect(find.textContaining('Link: /'), findsOneWidget);
    expect((await repo.listInbox()).firstWhere((i) => i.id == 'n1').isUnread,
        isFalse);
  });

  testWidgets('shows empty state when inbox has no items', (tester) async {
    final empty = FakeStudentNotificationInboxRepository(seed: const []);
    await tester.pumpWidget(_host(empty));
    await tester.pumpAndSettle();
    expect(find.text('No notifications yet'), findsOneWidget);
  });

  testWidgets('shows error state when inbox fails to load', (tester) async {
    final failing = FakeStudentNotificationInboxRepository()..alwaysFail = true;
    await tester.pumpWidget(_host(failing));
    await tester.pumpAndSettle();
    expect(find.text('Could not load notifications'), findsOneWidget);
    expect(find.text('Try again'), findsOneWidget);
  });
}
