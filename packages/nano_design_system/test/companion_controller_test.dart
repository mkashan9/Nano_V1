import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  var now = DateTime.utc(2026, 8, 1, 9);

  setUp(() => now = DateTime.utc(2026, 8, 1, 9));

  CompanionController controller({
    bool junior = true,
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    String companionName = 'Nori',
  }) {
    final created = CompanionController(
      junior: junior,
      preferences: preferences,
      companionName: companionName,
      clock: () => now,
    );
    addTearDown(created.dispose);
    return created;
  }

  group('session continuity', () {
    test('a cooldown survives moving between surfaces', () {
      final companion = controller();
      companion.report(CompanionEvent.home);
      final first = companion.reaction!.script.id;

      companion.enterSurface(CompanionSurface.learning);
      expect(companion.reaction, isNull);

      companion.enterSurface(CompanionSurface.home);
      now = now.add(const Duration(seconds: 2));
      companion.report(CompanionEvent.home, seed: 1);
      expect(companion.reaction, isNull, reason: 'still cooling down');

      now = now.add(const Duration(seconds: 30));
      companion.report(CompanionEvent.home, seed: 1);
      expect(companion.reaction!.script.id, isNot(first));
    });

    test('the appearance budget is shared across surfaces', () {
      final companion = controller();
      for (final moment in const [
        (CompanionSurface.home, CompanionEvent.home),
        (CompanionSurface.learning, CompanionEvent.learningEntry),
        (CompanionSurface.learning, CompanionEvent.videoStart),
        (CompanionSurface.quiz, CompanionEvent.quizStart),
        (CompanionSurface.quiz, CompanionEvent.quizQuestion),
        (CompanionSurface.progress, CompanionEvent.emptyState),
      ]) {
        now = now.add(const Duration(minutes: 1));
        companion.report(moment.$2, surface: moment.$1);
      }
      expect(
        companion.runtime.shownThisSession,
        CompanionRules.junior.maxPerSession,
      );

      now = now.add(const Duration(minutes: 1));
      companion.report(CompanionEvent.idle, surface: CompanionSurface.home);
      expect(companion.reaction, isNull);
    });

    test('ending the session starts the budget over', () {
      final companion = controller();
      companion.report(CompanionEvent.home);
      companion.endSession();
      expect(companion.runtime.shownThisSession, 0);
      expect(companion.reaction, isNull);
    });
  });

  group('one companion at a time', () {
    test('only the surface in front is current', () {
      final companion = controller();
      companion.report(CompanionEvent.home, surface: CompanionSurface.home);
      expect(companion.isCurrent(CompanionSurface.home), isTrue);

      companion.enterSurface(CompanionSurface.learning);
      expect(companion.isCurrent(CompanionSurface.home), isFalse);
      expect(companion.isCurrent(CompanionSurface.learning), isTrue);
    });

    test('re-entering the same surface keeps the reaction', () {
      final companion = controller();
      companion.report(CompanionEvent.home);
      companion.enterSurface(CompanionSurface.home);
      expect(companion.reaction, isNotNull);
    });
  });

  group('returning after a while', () {
    test('a long gap is greeted', () {
      final companion = controller();
      companion.report(CompanionEvent.home);
      companion.dismiss();

      now = now.add(const Duration(hours: 3));
      companion.appResumed();
      expect(
        companion.reaction!.event,
        CompanionEvent.returnFromInactivity,
      );
    });

    test('a short gap is not', () {
      final companion = controller();
      companion.report(CompanionEvent.home);
      companion.dismiss();

      now = now.add(const Duration(seconds: 20));
      companion.appResumed();
      expect(companion.reaction, isNull);
    });
  });

  test('preference changes reach the live controller', () {
    final companion = controller();
    var notified = 0;
    companion.addListener(() => notified++);

    companion.updatePreferences(
      const AccessibilityPreferences(soundEnabled: false),
    );
    expect(notified, 1);

    companion.report(CompanionEvent.home);
    expect(companion.reaction!.speaks, isFalse);
  });

  test('a suppressed moment notifies nobody', () {
    final companion = controller(junior: false);
    var notified = 0;
    companion.addListener(() => notified++);

    companion.report(CompanionEvent.home);
    expect(companion.reaction, isNull);
    expect(notified, 0);
  });

  testWidgets('the scope shares one controller with every surface',
      (tester) async {
    final companion = controller();
    var homeBuilds = 0;
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: NanoCompanionScope(
          controller: companion,
          child: MaterialApp(
            home: Scaffold(
              body: Builder(
                builder: (context) {
                  homeBuilds++;
                  return const CompanionSurfaceStage(
                    surface: CompanionSurface.home,
                    junior: true,
                    entryEvent: CompanionEvent.home,
                  );
                },
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(homeBuilds, 1, reason: 'the stage listens, not its parent');
    expect(find.byType(CompanionSlot), findsOneWidget);
    expect(companion.reaction!.event, CompanionEvent.home);

    await tester.tap(find.byIcon(Icons.close));
    await tester.pumpAndSettle();
    expect(companion.reaction, isNull);
    expect(find.byType(CompanionSlot), findsNothing);
  });

  testWidgets('a hidden surface neither shows nor reports', (tester) async {
    final companion = controller();
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: NanoCompanionScope(
          controller: companion,
          child: const MaterialApp(
            home: Scaffold(
              body: CompanionSurfaceStage(
                surface: CompanionSurface.settings,
                junior: true,
                entryEvent: CompanionEvent.home,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(CompanionSlot), findsNothing);
    expect(companion.reaction, isNull);
    expect(companion.runtime.shownThisSession, 0);
  });

  testWidgets('senior home entry stays quiet, junior home greets',
      (tester) async {
    Future<CompanionReaction?> enterHome({required bool junior}) async {
      final companion = controller(junior: junior);
      await tester.pumpWidget(
        NanoLocaleScope(
          locale: NanoAppLocale.en,
          copy: const NanoCopy(NanoAppLocale.en),
          child: NanoCompanionScope(
            controller: companion,
            child: MaterialApp(
              home: Scaffold(
                body: CompanionSurfaceStage(
                  key: ValueKey(junior),
                  surface: CompanionSurface.home,
                  junior: junior,
                  entryEvent: CompanionEvent.home,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return companion.reaction;
    }

    expect((await enterHome(junior: true))!.mood, CompanionMood.greeting);
    expect(await enterHome(junior: false), isNull);
  });

  testWidgets('placement decides the size, not the screen', (tester) async {
    Future<double> sizeFor({required bool junior}) async {
      final companion = controller(junior: junior);
      await tester.pumpWidget(
        NanoLocaleScope(
          locale: NanoAppLocale.en,
          copy: const NanoCopy(NanoAppLocale.en),
          child: NanoCompanionScope(
            controller: companion,
            child: MaterialApp(
              home: Scaffold(
                body: CompanionSurfaceStage(
                  // A fresh state per experience, so the entry moment is
                  // reported again rather than reusing the previous mount.
                  key: ValueKey(junior),
                  surface: CompanionSurface.home,
                  junior: junior,
                  // Senior stays quiet about `home` itself, so this compares
                  // placement rather than the quiet list.
                  entryEvent: CompanionEvent.appOpen,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return tester.getSize(find.byType(CompanionSlot)).width;
    }

    final juniorSize = await sizeFor(junior: true);
    final seniorSize = await sizeFor(junior: false);
    expect(
      juniorSize,
      CompanionStage.artSizeFor(
        placement: CompanionPlacement.hero,
        prominent: true,
        storyCard: false,
      ),
    );
    expect(seniorSize, lessThan(juniorSize));
  });
}
