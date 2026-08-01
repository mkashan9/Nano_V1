import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';

/// MED-08: the controller side of playback.
///
/// The seams were always here; nothing was ever attached to them. These tests
/// pin what happens once something is: a picture gets a URL, a clip that ends
/// puts the still back, and a resolver that fails is a fallback rather than an
/// exception thrown at a widget.
void main() {
  final now = DateTime.utc(2026, 8, 1, 9);

  GeneratedAsset asset({
    required String slot,
    required GeneratedAssetKind kind,
    String id = '',
  }) =>
      GeneratedAsset(
        id: id.isEmpty ? 'asset-$slot' : id,
        kind: kind,
        slot: slot,
        locale: 'en',
        aspectRatio: '1:1',
        moderation: GeneratedAssetModeration.approved,
        storageBucket: 'generated-assets',
        storagePath: '${kind.name}/$slot/en/hash',
        contentType: kind == GeneratedAssetKind.video ? 'video/mp4' : 'image/jpeg',
        byteSize: 2048,
        checksum: 'sha256:$slot',
        completedAt: DateTime.utc(2026, 8, 1),
      );

  CompanionController controller({
    Set<String> clipSlots = const {},
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
  }) {
    final created = CompanionController(
      junior: true,
      preferences: preferences,
      clock: () => now,
      clipSlots: clipSlots,
    );
    addTearDown(created.dispose);
    return created;
  }

  test('an approved picture becomes a URL the stage can draw', () async {
    final companion = controller();
    companion.report(CompanionEvent.appOpen);
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([
        asset(
          slot: 'guide_greeting_staticArt',
          kind: GeneratedAssetKind.image,
        ),
      ]),
      resolveUrl: (asset) async => 'https://signed.test/${asset.id}',
    );

    expect(companion.art?.hasStill, isTrue);
    await Future<void>.delayed(Duration.zero);
    expect(companion.artUrl, 'https://signed.test/asset-guide_greeting_staticArt');
  });

  test('static art fills a slot the reaction asked for at another tier',
      () async {
    // Greeting resolves to localAnimation, and nobody publishes art per tier —
    // the picture lives at the static-art slot and holds up every rung above it.
    final companion = controller();
    companion.report(CompanionEvent.appOpen);
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([
        asset(
          slot: 'guide_greeting_staticArt',
          kind: GeneratedAssetKind.image,
        ),
      ]),
      resolveUrl: (asset) async => 'https://signed.test/${asset.id}',
    );
    await Future<void>.delayed(Duration.zero);

    expect(companion.reaction!.tier, CompanionAssetTier.localAnimation);
    expect(companion.artUrl, isNotNull);
  });

  test('a resolver that fails leaves the placeholder, and throws at nobody',
      () async {
    final companion = controller();
    companion.report(CompanionEvent.appOpen);
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([
        asset(
          slot: 'guide_greeting_staticArt',
          kind: GeneratedAssetKind.image,
        ),
      ]),
      resolveUrl: (asset) async => throw StateError('expired'),
    );
    await Future<void>.delayed(Duration.zero);

    expect(companion.artUrl, isNull);
  });

  test('a picture minted after the reaction moved on is discarded', () async {
    final companion = controller();
    companion.report(CompanionEvent.appOpen);
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([
        asset(slot: 'guide_greeting_staticArt', kind: GeneratedAssetKind.image),
        asset(slot: 'explorer_point_staticArt', kind: GeneratedAssetKind.image),
      ]),
      resolveUrl: (asset) async {
        await Future<void>.delayed(const Duration(milliseconds: 20));
        return 'https://signed.test/${asset.id}';
      },
    );
    // Move on before the greeting's URL can land. A slow mint that painted
    // anyway would show the wrong Nori under the right caption.
    companion.report(
      CompanionEvent.learningEntry,
      surface: CompanionSurface.learning,
    );
    await Future<void>.delayed(const Duration(milliseconds: 60));

    expect(companion.reaction!.mood, CompanionMood.point);
    expect(
      companion.artUrl,
      'https://signed.test/asset-explorer_point_staticArt',
    );
  });

  test('a clip that ends on its own tells the stage to go back to the still',
      () async {
    final companion = controller(clipSlots: {'guide_greeting_shortClip'});
    final player = NanoRecordingClipPlayer();
    companion.report(CompanionEvent.appOpen);
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([
        asset(slot: 'guide_greeting_shortClip', kind: GeneratedAssetKind.video),
      ]),
      player: player,
      resolveUrl: (asset) async => 'https://signed.test/${asset.id}',
    );

    var notifications = 0;
    companion.addListener(() => notifications++);

    expect(companion.canShowClip, isTrue);
    await companion.playClip();
    expect(player.played.single, 'https://signed.test/asset-guide_greeting_shortClip');
    expect(notifications, greaterThan(0));

    final before = notifications;
    // The player reaching its end is not something the controller asked for.
    await player.stop();
    expect(notifications, greaterThan(before));
    expect(companion.isPlayingClip, isFalse);
  });

  test('reduced motion never gets a clip control, published or not', () {
    final companion = controller(
      clipSlots: {'guide_greeting_shortClip'},
      preferences: const AccessibilityPreferences(reducedMotion: true),
    );
    companion.report(CompanionEvent.appOpen);
    companion.attachClips(
      catalog: CompanionAssetCatalog.fromAssets([
        asset(slot: 'guide_greeting_shortClip', kind: GeneratedAssetKind.video),
      ]),
      player: NanoRecordingClipPlayer(),
      resolveUrl: (asset) async => 'https://signed.test/${asset.id}',
    );

    expect(companion.canShowClip, isFalse);
  });

  test('the voice seam notifies, so a stop control can follow it', () async {
    final player = NanoRecordingVoicePlayer();
    var notifications = 0;
    player.addListener(() => notifications++);

    await player.play('https://signed.test/line.mp3');
    expect(player.isPlaying, isTrue);
    await player.stop();
    expect(player.isPlaying, isFalse);
    expect(notifications, 2);
  });
}
