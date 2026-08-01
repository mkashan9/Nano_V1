import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_media/nano_media.dart';

/// MED-03: the listen control exists only when it can work, tapping it plays the
/// line on screen, and the caption is never affected by any of it.
void main() {
  const audio = NarrationAudio(
    storageBucket: 'generated-assets',
    storagePath: 'voice/narration_celebration-1/en/hash.wav',
    contentType: 'audio/wav',
    byteSize: 4096,
    checksum: 'sha256:celebration',
  );

  NarrationCatalog catalogWith({
    String text = 'Nicely done!',
    NarrationAudio? withAudio = audio,
  }) =>
      NarrationCatalog.fromLines(
        [
          NarrationLine(
            slug: 'celebration-1',
            locale: NanoAppLocale.en,
            text: text,
            audio: withAudio,
          ),
        ],
        locale: NanoAppLocale.en,
      );

  CompanionController controllerWith({
    NarrationCatalog? catalog,
    NanoVoicePlayer? player,
    NarrationCache? cache,
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
  }) {
    final controller = CompanionController(
      junior: true,
      preferences: preferences,
      surface: CompanionSurface.quiz,
      clock: () => DateTime.utc(2026, 8, 1, 9),
    );
    controller.attachNarration(
      catalog: catalog,
      player: player,
      resolveUrl: (audio) async => 'https://signed.local/${audio.checksum}',
    );
    controller.report(CompanionEvent.quizComplete, surface: CompanionSurface.quiz);
    return controller;
  }

  Future<void> pump(WidgetTester tester, CompanionController controller) async {
    await tester.pumpWidget(
      MaterialApp(
        home: NanoCompanionScope(
          controller: controller,
          child: const Scaffold(
            body: CompanionSurfaceStage(
              surface: CompanionSurface.quiz,
              junior: true,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('with no player there is no listen control', (tester) async {
    // The state of the app today: a catalog may arrive, but nothing can play it.
    final controller = controllerWith(catalog: catalogWith());
    await pump(tester, controller);

    expect(controller.narration?.canSpeak, isTrue);
    expect(controller.canSpeak, isFalse);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.text('Nicely done!'), findsOneWidget);
  });

  testWidgets('with a recording and a player, the line can be heard',
      (tester) async {
    final player = NanoRecordingVoicePlayer();
    final controller = controllerWith(catalog: catalogWith(), player: player);
    await pump(tester, controller);

    expect(find.byIcon(Icons.volume_up_rounded), findsOneWidget);
    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();

    expect(player.played, ['https://signed.local/sha256:celebration']);
    // The caption did not move to make room for the sound.
    expect(find.text('Nicely done!'), findsOneWidget);
  });

  testWidgets('a line nobody recorded shows no control and no error',
      (tester) async {
    final controller = controllerWith(
      catalog: catalogWith(withAudio: null),
      player: NanoRecordingVoicePlayer(),
    );
    await pump(tester, controller);

    expect(controller.narration?.fallback, NarrationFallback.noRecording);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.text('Nicely done!'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a muted learner reads the line and is offered nothing to play',
      (tester) async {
    final controller = controllerWith(
      catalog: catalogWith(),
      player: NanoRecordingVoicePlayer(),
      preferences:
          AccessibilityPreferences.defaults.copyWith(soundEnabled: false),
    );
    await pump(tester, controller);

    expect(controller.narration?.fallback, NarrationFallback.soundOff);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
    expect(find.text('Nicely done!'), findsOneWidget);
  });

  testWidgets('Classroom Mode is silent even with sound on', (tester) async {
    final controller = controllerWith(
      catalog: catalogWith(),
      player: NanoRecordingVoicePlayer(),
      preferences:
          AccessibilityPreferences.defaults.copyWith(classroomMode: true),
    );
    await pump(tester, controller);

    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
  });

  testWidgets('a recording of different words is never offered', (tester) async {
    final controller = controllerWith(
      catalog: catalogWith(text: 'An older sentence entirely.'),
      player: NanoRecordingVoicePlayer(),
    );
    await pump(tester, controller);

    expect(controller.narration?.fallback, NarrationFallback.wordingChanged);
    expect(find.byIcon(Icons.volume_up_rounded), findsNothing);
  });

  testWidgets('a new line stops the previous one being audible', (tester) async {
    final player = NanoRecordingVoicePlayer();
    final controller = controllerWith(catalog: catalogWith(), player: player);
    await pump(tester, controller);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();
    expect(player.isPlaying, isTrue);

    controller.dismiss();
    await tester.pumpAndSettle();

    expect(player.stopCount, 1);
    expect(player.isPlaying, isFalse);
  });

  testWidgets('learning that a recording exists disturbs nothing on screen',
      (tester) async {
    final player = NanoRecordingVoicePlayer();
    final controller = controllerWith(player: player);
    await pump(tester, controller);

    final before = controller.reaction;
    expect(controller.canSpeak, isFalse);

    // The catalog arrives late, the way it really does.
    controller.attachNarration(catalog: catalogWith());
    await tester.pumpAndSettle();

    expect(controller.reaction, same(before));
    expect(controller.canSpeak, isTrue);
    expect(find.text('Nicely done!'), findsOneWidget);
  });

  testWidgets('a URL that cannot be minted plays nothing and says nothing',
      (tester) async {
    final player = NanoRecordingVoicePlayer();
    final controller = CompanionController(
      junior: true,
      surface: CompanionSurface.quiz,
      clock: () => DateTime.utc(2026, 8, 1, 9),
    );
    controller.attachNarration(
      catalog: catalogWith(),
      player: player,
      // What a failed or expired signing attempt looks like.
      resolveUrl: (_) async => null,
    );
    controller.report(
      CompanionEvent.quizComplete,
      surface: CompanionSurface.quiz,
    );
    await pump(tester, controller);

    await tester.tap(find.byIcon(Icons.volume_up_rounded));
    await tester.pumpAndSettle();

    expect(player.played, isEmpty);
    expect(tester.takeException(), isNull);
    expect(find.text('Nicely done!'), findsOneWidget);
  });
}
