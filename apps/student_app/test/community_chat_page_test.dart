import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/communities/presentation/community_chat_page.dart';

void main() {
  testWidgets('community chat lists seed messages and sends', (tester) async {
    final messaging = FakeCommunityMessagingRepository();
    await tester.binding.setSurfaceSize(const Size(800, 1200));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.senior(),
          home: CommunityChatPage(
            communityId: 'a1000000-0000-4000-8000-000000000001',
            communityName: 'Study Circle',
            messagingRepository: messaging,
            discoveryRepository: FakeCommunityDiscoveryRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.text('Welcome to Study Circle — ask anything.'), findsWidgets);
    expect(find.text('lab.jpg'), findsOneWidget);
    expect(find.text('Pins'), findsWidgets);

    await tester.tap(find.byIcon(Icons.search));
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField).last, 'Welcome');
    await tester.tap(find.byIcon(Icons.search).last);
    await tester.pumpAndSettle();
    expect(find.text('Ayesha'), findsWidgets);
    Navigator.of(tester.element(find.text('Search messages'))).pop();
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.add_circle_outline));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Photo'));
    await tester.pumpAndSettle();
    expect(find.text('photo-demo'), findsOneWidget);

    await tester.enterText(find.byType(TextField), 'Hello chat');
    await tester.tap(find.widgetWithText(FilledButton, 'Send'));
    await tester.pumpAndSettle();
    expect(find.text('Hello chat'), findsOneWidget);
    expect(find.text('photo-demo'), findsWidgets);
  });
}
