import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// MED-08 and MED-09: what actually gets drawn inside the mode ring.
///
/// Before MED-08 the answer was always a Material icon — there was no code path
/// that could show a picture, however much art had been approved. MED-08 added
/// the published rung and MED-09 added the bundled one beneath it, which is
/// what pushes the icon out of reach: a bundled pose needs no network, no
/// session, and nobody's approval.
///
/// These tests pin the whole ladder: clip, published picture, bundled pose,
/// icon — and never an empty frame.
void main() {
  CompanionReaction reactionFor(CompanionMood mood) => CompanionReaction(
        event: CompanionEvent.appOpen,
        mood: mood,
        script: const CompanionScript(
          id: 'greeting-2',
          text: 'Good to see you again.',
        ),
        tier: CompanionAssetTier.staticArt,
        prominent: true,
      );

  Future<void> pumpStage(
    WidgetTester tester, {
    String? artUrl,
    Widget? clipView,
    bool clipAvailable = false,
    CompanionMood mood = CompanionMood.greeting,
  }) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          home: Scaffold(
            body: CompanionStage(
              reaction: reactionFor(mood),
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

  /// Every bundled pose currently in the tree.
  ///
  /// A set rather than the first hit, because the published rung renders its
  /// fallback *inside* itself: `Image.network` builds, and its frameBuilder
  /// returns the bundled `Image` as a child while the download is in flight.
  /// Both are real widgets and only one of them is painting.
  Set<String> bundledPaths(WidgetTester tester) => tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .whereType<AssetImage>()
      .map((provider) => provider.assetName)
      .toSet();

  Set<String> networkUrls(WidgetTester tester) => tester
      .widgetList<Image>(find.byType(Image))
      .map((image) => image.image)
      .whereType<NetworkImage>()
      .map((provider) => provider.url)
      .toSet();

  testWidgets('with nothing published the bundled pose is the picture',
      (tester) async {
    await pumpStage(tester);

    expect(
      bundledPaths(tester),
      {NoriPosePack.assetFor(CompanionMood.greeting)},
    );
    // The icon was the floor before MED-09. It is now unreachable unless the
    // bundle itself is broken.
    expect(find.byIcon(Icons.waving_hand_rounded), findsNothing);
  });

  testWidgets('the bundled pose follows the mood, not the mode',
      (tester) async {
    for (final mood in CompanionMood.values) {
      await pumpStage(tester, mood: mood);
      await tester.pumpAndSettle();
      expect(
        bundledPaths(tester),
        {NoriPosePack.assetFor(mood)},
        reason: '${mood.name} must draw its own pose and only its own',
      );
    }
  });

  testWidgets('an approved picture is drawn instead of the bundled pose',
      (tester) async {
    await pumpStage(tester, artUrl: 'https://example.test/nori-greeting.jpg');

    expect(networkUrls(tester), {'https://example.test/nori-greeting.jpg'});
  });

  testWidgets('a picture that will not load falls to the bundled pose',
      (tester) async {
    // The test binding refuses network images, which is exactly the field
    // condition worth pinning: an expired URL, a dead link, no connection.
    await pumpStage(tester, artUrl: 'https://example.test/missing.jpg');
    await tester.pump();

    expect(
      bundledPaths(tester),
      contains(NoriPosePack.assetFor(CompanionMood.greeting)),
    );
    expect(find.byIcon(Icons.waving_hand_rounded), findsNothing);
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
