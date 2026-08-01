import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';

void main() {
  var now = DateTime.utc(2026, 8, 1, 9);

  setUp(() => now = DateTime.utc(2026, 8, 1, 9));

  GeneratedAsset clip({
    String slot = 'celebration_celebration_shortClip',
  }) =>
      GeneratedAsset(
        id: 'clip-$slot',
        kind: GeneratedAssetKind.video,
        slot: slot,
        locale: 'en',
        aspectRatio: '1:1',
        moderation: GeneratedAssetModeration.approved,
        storageBucket: 'generated-assets',
        storagePath: 'video/$slot/en/hash.mp4',
        contentType: 'video/mp4',
        byteSize: 4096,
        checksum: 'sha256:$slot',
        completedAt: DateTime.utc(2026, 8, 1),
      );

  CompanionController controller({
    bool clipsAvailable = false,
    Set<String> clipSlots = const {},
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
  }) {
    final created = CompanionController(
      junior: true,
      preferences: preferences,
      clock: () => now,
      clipsAvailable: clipsAvailable,
      clipSlots: clipSlots,
    );
    addTearDown(created.dispose);
    return created;
  }

  Future<void> pumpSurface(
    WidgetTester tester,
    CompanionController companion, {
    CompanionEvent entry = CompanionEvent.levelUp,
  }) async {
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: NanoCompanionScope(
          controller: companion,
          child: MaterialApp(
            home: Scaffold(
              body: CompanionSurfaceStage(
                surface: CompanionSurface.home,
                junior: true,
                entryEvent: entry,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('no player means no play affordance, even when a clip exists',
      (tester) async {
    final companion = controller(
      clipSlots: {'celebration_celebration_shortClip'},
    );
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([clip()]),
      // No player, no resolveUrl — the ordinary resting state.
    );

    await pumpSurface(tester, companion);

    expect(companion.reaction!.tier, CompanionAssetTier.shortClip);
    expect(companion.canShowClip, isFalse);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('a clip and a player offer a tap that plays the signed URL',
      (tester) async {
    final player = NanoRecordingClipPlayer();
    final companion = controller(
      clipSlots: {'celebration_celebration_shortClip'},
    );
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([clip()]),
      player: player,
      resolveUrl: (asset) async =>
          'https://fake.local/${asset.storagePath}?sig=1',
    );

    await pumpSurface(tester, companion);

    expect(companion.canShowClip, isTrue);
    expect(find.byIcon(Icons.play_arrow_rounded), findsOneWidget);

    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();

    expect(player.played, [
      'https://fake.local/video/celebration_celebration_shortClip/en/hash.mp4?sig=1',
    ]);
  });

  testWidgets('reduced motion never offers a clip, even when one exists',
      (tester) async {
    final player = NanoRecordingClipPlayer();
    final companion = controller(
      clipSlots: {'celebration_celebration_shortClip'},
      preferences: const AccessibilityPreferences(reducedMotion: true),
    );
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([clip()]),
      player: player,
      resolveUrl: (asset) async => 'https://fake.local/${asset.storagePath}',
    );

    await pumpSurface(tester, companion);

    expect(companion.reaction!.tier, CompanionAssetTier.staticArt);
    expect(companion.art!.usesGeneratedClip, isFalse);
    expect(companion.canShowClip, isFalse);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('a missing clip for this slot keeps local art', (tester) async {
    final player = NanoRecordingClipPlayer();
    final companion = controller(
      // A greeting clip exists; this surface is celebrating.
      clipSlots: {'guide_greeting_shortClip'},
    );
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([
        clip(slot: 'guide_greeting_shortClip'),
      ]),
      player: player,
      resolveUrl: (asset) async => 'https://fake.local/${asset.storagePath}',
    );

    await pumpSurface(tester, companion);

    expect(companion.reaction!.tier, CompanionAssetTier.localAnimation);
    expect(companion.art!.usesGeneratedClip, isFalse);
    expect(companion.canShowClip, isFalse);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('dismiss stops playback', (tester) async {
    final player = NanoRecordingClipPlayer();
    final companion = controller(
      clipSlots: {'celebration_celebration_shortClip'},
    );
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([clip()]),
      player: player,
      resolveUrl: (asset) async => 'https://fake.local/${asset.storagePath}',
    );

    await pumpSurface(tester, companion);
    await tester.tap(find.byIcon(Icons.play_arrow_rounded));
    await tester.pumpAndSettle();
    expect(player.isPlaying, isTrue);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();

    expect(player.isPlaying, isFalse);
    expect(player.stopCount, greaterThan(0));
    expect(companion.reaction, isNull);
  });

  test('clipsAvailable stays a boolean; clipSlots is the finer answer', () {
    final companion = controller();
    expect(companion.clipsAvailable, isFalse);
    expect(companion.clipSlots, isEmpty);

    companion.setClipSlots({'celebration_celebration_shortClip'});
    expect(companion.clipsAvailable, isTrue);
    expect(companion.clipSlots, {'celebration_celebration_shortClip'});

    companion.setClipsAvailable(false);
    // The coarser setter still works for MED-02 callers; it does not clear the
    // slot list, because the two answers arrive from different places.
    expect(companion.clipsAvailable, isFalse);
  });
}
