import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// MED-08: what actually gets drawn inside the mode ring.
///
/// Before this module the answer was always a Material icon — there was no code
/// path that could show a picture, however much art had been approved. These
/// tests pin the ladder: clip, then approved picture, then icon, and never an
/// empty frame.
void main() {
  const reaction = CompanionReaction(
    event: CompanionEvent.appOpen,
    mood: CompanionMood.greeting,
    script: CompanionScript(id: 'greeting-2', text: 'Good to see you again.'),
    tier: CompanionAssetTier.staticArt,
    prominent: true,
  );

  Future<void> pumpStage(
    WidgetTester tester, {
    String? artUrl,
    Widget? clipView,
    bool clipAvailable = false,
  }) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          home: Scaffold(
            body: CompanionStage(
              reaction: reaction,
              artUrl: artUrl,
              clipView: clipView,
              clipAvailable: clipAvailable,
            ),
          ),
        ),
      ),
    );
    await tester.pump();
  }

  testWidgets('with nothing published the mood icon is the picture',
      (tester) async {
    await pumpStage(tester);

    expect(find.byIcon(Icons.waving_hand_rounded), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an approved picture is drawn instead of the icon',
      (tester) async {
    await pumpStage(tester, artUrl: 'https://example.test/nori-greeting.jpg');

    final image = tester.widget<Image>(find.byType(Image));
    expect((image.image as NetworkImage).url,
        'https://example.test/nori-greeting.jpg');
  });

  testWidgets('a picture that will not load leaves the icon, never a hole',
      (tester) async {
    // The test binding refuses network images, which is exactly the field
    // condition worth pinning: an expired URL, a dead link, no connection.
    await pumpStage(tester, artUrl: 'https://example.test/missing.jpg');
    await tester.pump();

    expect(find.byIcon(Icons.waving_hand_rounded), findsOneWidget);
  });

  testWidgets('a clip that is playing takes the frame, and the badge goes',
      (tester) async {
    await pumpStage(
      tester,
      artUrl: 'https://example.test/nori-greeting.jpg',
      clipAvailable: true,
      clipView: const SizedBox(key: Key('clip'), width: 64, height: 64),
    );

    expect(find.byKey(const Key('clip')), findsOneWidget);
    // The play badge invites a tap; while the clip is on screen there is
    // nothing left to invite.
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('an available clip that is not playing shows the play badge',
      (tester) async {
    await pumpStage(tester, clipAvailable: true);

    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);
  });
}
