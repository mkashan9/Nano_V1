import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 1, 9);

  CompanionReaction reactionFor(
    CompanionEvent event, {
    CompanionSurface surface = CompanionSurface.home,
    bool junior = true,
  }) {
    return CompanionRuntime.forExperience(junior: junior, surface: surface)
        .notify(event, now: t0)
        .reaction!;
  }

  Future<void> pump(
    WidgetTester tester,
    CompanionReaction reaction, {
    NanoAppLocale locale = NanoAppLocale.en,
    Widget? action,
    VoidCallback? onDismiss,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: locale,
        copy: NanoCopy(locale),
        child: MaterialApp(
          home: Scaffold(
            body: CompanionStage(
              reaction: reaction,
              locale: locale,
              action: action,
              onDismiss: onDismiss,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('names which companion mode is speaking', (tester) async {
    await pump(
      tester,
      reactionFor(CompanionEvent.quizStart, surface: CompanionSurface.quiz),
    );
    expect(find.text('Nori · Quiz coach'), findsOneWidget);
    expect(find.byIcon(Icons.school_rounded), findsOneWidget);
  });

  testWidgets('each mode carries its own accent and emblem', (tester) async {
    final seen = <Color>{};
    for (final entry in const {
      CompanionSurface.learning: CompanionMode.explorer,
      CompanionSurface.quiz: CompanionMode.quizCoach,
      CompanionSurface.game: CompanionMode.builder,
      CompanionSurface.settings: CompanionMode.guide,
    }.entries) {
      final reaction = reactionFor(
        CompanionEvent.emptyState,
        surface: entry.key,
      );
      expect(reaction.mode, entry.value);
      await pump(tester, reaction);
      final mode = CompanionModeTheme.of(entry.value);
      expect(find.byIcon(mode.emblem), findsOneWidget);
      seen.add(mode.accent);
    }
    expect(seen, hasLength(4));
  });

  testWidgets('modes share one frame: same slot, same caption bubble',
      (tester) async {
    await pump(
      tester,
      reactionFor(CompanionEvent.videoStart, surface: CompanionSurface.learning),
    );
    final explorerSize = tester.getSize(find.byType(CompanionSlot));
    final explorerCaption = tester.widget<Text>(
      find.text('Start here.'),
    );

    await pump(
      tester,
      reactionFor(CompanionEvent.quizStart, surface: CompanionSurface.quiz),
    );
    expect(tester.getSize(find.byType(CompanionSlot)), explorerSize);
    expect(
      tester.widget<Text>(find.text('Start here.')).style,
      explorerCaption.style,
    );
  });

  testWidgets('a rare moment becomes a framed story card', (tester) async {
    await pump(
      tester,
      reactionFor(
        CompanionEvent.newWorld,
        surface: CompanionSurface.learning,
      ),
      action: const Text('See it'),
    );

    expect(find.text('Nori · Explorer'), findsOneWidget);
    expect(find.text('See it'), findsOneWidget);
    // Story cards get more room than inline guidance.
    final storySize = tester.getSize(find.byType(CompanionSlot));

    await pump(
      tester,
      reactionFor(
        CompanionEvent.videoStart,
        surface: CompanionSurface.learning,
      ),
    );
    expect(
      tester.getSize(find.byType(CompanionSlot)).width,
      lessThan(storySize.width),
    );
  });

  testWidgets('an ordinary moment stays inline with no action slot',
      (tester) async {
    await pump(
      tester,
      reactionFor(CompanionEvent.home),
      action: const Text('See it'),
    );
    expect(find.text('See it'), findsNothing);
  });

  testWidgets('a story card can be dismissed', (tester) async {
    var dismissed = false;
    await pump(
      tester,
      reactionFor(
        CompanionEvent.levelUp,
        surface: CompanionSurface.progress,
      ),
      onDismiss: () => dismissed = true,
    );
    expect(find.text('Nori · Celebration'), findsOneWidget);
    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });

  testWidgets('mode names are localised', (tester) async {
    await pump(
      tester,
      reactionFor(CompanionEvent.quizStart, surface: CompanionSurface.quiz),
      locale: NanoAppLocale.ur,
    );
    expect(find.textContaining('کوئز کوچ'), findsOneWidget);
  });
}
