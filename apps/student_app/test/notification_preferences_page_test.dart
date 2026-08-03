import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/notifications/presentation/notification_preferences_page.dart';
import 'package:student_app/features/profile/presentation/student_profile_page.dart';

void main() {
  testWidgets('toggles quiet hours and saves', (tester) async {
    final prefs = FakeNotificationPreferencesRepository();
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: NotificationPreferencesPage(
            preferencesRepository: prefs,
            userId: 'u1',
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Notification preferences'), findsOneWidget);
    await tester.tap(find.text('Quiet hours'));
    await tester.pumpAndSettle();
    expect(find.text('Preferences saved'), findsOneWidget);
    expect((await prefs.load(userId: 'u1')).quietHoursEnabled, isTrue);
  });

  testWidgets('profile opens notification preferences', (tester) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: Scaffold(
            body: StudentProfilePage(
              repository: FakeStudentProfileRepository(),
              principal: SessionPrincipal.seniorSchool().copyWith(userId: 'u1'),
              notificationPreferencesRepository:
                  FakeNotificationPreferencesRepository(),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('Notification preferences'));
    await tester.pumpAndSettle();
    expect(find.text('Quiet hours'), findsOneWidget);
  });
}
