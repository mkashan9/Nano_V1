import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

/// MED-08: approved media finally reaching a learner, and the rules that decide
/// when it must not.
///
/// The whole delivery pipeline existed before this module and none of it was
/// ever attached to a screen. These tests run the real app shell with real
/// repositories and the recording players, so what they prove is the wiring:
/// a picture appears, a control appears only when it can work, and every
/// accessibility setting takes precedence over anything published.
void main() {
  const config = EnvironmentConfig(
    environment: NanoEnvironment.development,
    supabaseUrl: '',
    supabaseAnonKey: '',
    featureFlags: {'diagnostics': true},
  );

  GeneratedAsset art({
    String slot = 'guide_greeting_staticArt',
    GeneratedAssetKind kind = GeneratedAssetKind.image,
  }) =>
      GeneratedAsset(
        id: 'asset-$slot',
        kind: kind,
        slot: slot,
        locale: 'en',
        aspectRatio: '1:1',
        moderation: GeneratedAssetModeration.approved,
        storageBucket: 'generated-assets',
        storagePath: '${kind.name}/$slot/en/hash',
        contentType:
            kind == GeneratedAssetKind.video ? 'video/mp4' : 'image/jpeg',
        byteSize: 2048,
        checksum: 'sha256:$slot',
        completedAt: DateTime.utc(2026, 8, 1),
      );

  Future<void> pumpApp(
    WidgetTester tester, {
    List<GeneratedAsset> published = const [],
    AccessibilityPreferences accessibility = AccessibilityPreferences.defaults,
    NanoClipPlayer? clipPlayer,
    NanoVoicePlayer? voicePlayer,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoStudentApp(
        config: config,
        initialAccessibility: accessibility,
        assetRepository: FakeGeneratedAssetRepository(seed: published),
        clipPlayer: clipPlayer,
        voicePlayer: voicePlayer,
      ),
    );
    await tester.pumpAndSettle();
  }

  CompanionController companionOf(WidgetTester tester) {
    final scope = tester.widget<NanoCompanionScope>(
      find.byType(NanoCompanionScope).first,
    );
    return scope.notifier!;
  }

  testWidgets('an approved picture reaches the screen as a picture',
      (tester) async {
    await pumpApp(tester, published: [art()]);
    await tester.pumpAndSettle();

    final companion = companionOf(tester);
    expect(companion.art?.hasStill, isTrue,
        reason: 'the catalog should resolve the published still');
    expect(companion.artUrl, isNotNull,
        reason: 'and a URL should have been minted for it');
    expect(find.byType(Image), findsWidgets);
    expect(tester.takeException(), isNull);
  });

  testWidgets('with nothing published the companion is still complete',
      (tester) async {
    await pumpApp(tester);

    final companion = companionOf(tester);
    expect(companion.artUrl, isNull);
    expect(companion.canShowClip, isFalse);
    // A reaction is on screen regardless: the picture was always the extra.
    expect(companion.reaction, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('no player means no control, however much is published',
      (tester) async {
    await pumpApp(
      tester,
      published: [
        art(),
        art(
          slot: 'guide_greeting_shortClip',
          kind: GeneratedAssetKind.video,
        ),
      ],
    );

    // A control that cannot work should not exist.
    expect(companionOf(tester).canShowClip, isFalse);
    expect(find.byIcon(Icons.play_arrow_rounded), findsNothing);
  });

  testWidgets('a clip plays only when the learner asks for it', (tester) async {
    final player = NanoRecordingClipPlayer();
    addTearDown(player.dispose);
    await pumpApp(
      tester,
      published: [
        art(),
        art(
          slot: 'guide_greeting_shortClip',
          kind: GeneratedAssetKind.video,
        ),
      ],
      clipPlayer: player,
    );
    await tester.pumpAndSettle();

    final companion = companionOf(tester);
    expect(companion.canShowClip, isTrue);
    // Nothing started on its own while the screen came up.
    expect(player.played, isEmpty);

    await companion.playClip();
    expect(player.played, hasLength(1));
  });

  testWidgets('reduced motion keeps the picture and refuses the clip',
      (tester) async {
    final player = NanoRecordingClipPlayer();
    addTearDown(player.dispose);
    await pumpApp(
      tester,
      published: [
        art(),
        art(
          slot: 'guide_greeting_shortClip',
          kind: GeneratedAssetKind.video,
        ),
      ],
      clipPlayer: player,
      accessibility: const AccessibilityPreferences(reducedMotion: true),
    );
    await tester.pumpAndSettle();

    final companion = companionOf(tester);
    expect(companion.canShowClip, isFalse);
    // The still is not motion, so it stays.
    expect(companion.artUrl, isNotNull);
  });

  testWidgets('Classroom Mode silences the voice without losing the words',
      (tester) async {
    final voice = NanoRecordingVoicePlayer();
    addTearDown(voice.dispose);
    await pumpApp(
      tester,
      published: [art()],
      voicePlayer: voice,
      accessibility: const AccessibilityPreferences(classroomMode: true),
    );

    final companion = companionOf(tester);
    expect(companion.canSpeak, isFalse);
    expect(voice.played, isEmpty);
    final reaction = companion.reaction;
    if (reaction != null) {
      // Classroom Mode suppresses most moments outright; when one does appear
      // it is readable and silent, never silent and blank.
      expect(reaction.showsCaption, isTrue);
      expect(reaction.speaks, isFalse);
    }
  });
}
