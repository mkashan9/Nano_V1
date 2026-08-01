import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 1, 9);

  CompanionRuntime junior({
    CompanionSurface surface = CompanionSurface.home,
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
  }) {
    return CompanionRuntime.forExperience(
      junior: true,
      surface: surface,
      preferences: preferences,
    );
  }

  group('modes', () {
    test('come from the surface, not the mood', () {
      expect(
        CompanionMode.resolve(
          surface: CompanionSurface.learning,
          event: CompanionEvent.videoStart,
        ),
        CompanionMode.explorer,
      );
      expect(
        CompanionMode.resolve(
          surface: CompanionSurface.quiz,
          event: CompanionEvent.quizQuestion,
        ),
        CompanionMode.quizCoach,
      );
      expect(
        CompanionMode.resolve(
          surface: CompanionSurface.game,
          event: CompanionEvent.emptyState,
        ),
        CompanionMode.builder,
      );
      expect(
        CompanionMode.resolve(
          surface: CompanionSurface.settings,
          event: CompanionEvent.home,
        ),
        CompanionMode.guide,
      );
    });

    test('a quiz coach celebrates without becoming Celebration Nori', () {
      final reaction = junior(surface: CompanionSurface.quiz)
          .notify(CompanionEvent.resultPassed, now: t0)
          .reaction!;
      expect(reaction.mood, CompanionMood.celebration);
      expect(reaction.mode, CompanionMode.quizCoach);
    });

    test('a milestone is Celebration Nori wherever it happens', () {
      for (final surface in CompanionSurface.values) {
        final reaction = junior(surface: surface)
            .notify(CompanionEvent.levelUp, now: t0)
            .reaction!;
        expect(reaction.mode, CompanionMode.celebration, reason: '$surface');
      }
    });

    test('a new world is an Explorer reveal, not a celebration', () {
      final reaction = junior(surface: CompanionSurface.home)
          .notify(CompanionEvent.newWorld, now: t0)
          .reaction!;
      expect(reaction.mode, CompanionMode.explorer);
      expect(reaction.mood, CompanionMood.point);
    });

    test('the mode is part of the asset key', () {
      final quiz = junior(surface: CompanionSurface.quiz)
          .notify(CompanionEvent.resultPassed, now: t0)
          .reaction!;
      final home = junior(surface: CompanionSurface.progress)
          .notify(CompanionEvent.resultPassed, now: t0)
          .reaction!;
      expect(quiz.mood, home.mood);
      expect(quiz.assetKey, isNot(home.assetKey));
      expect(quiz.assetKey, contains('quizCoach'));
    });

    test('every surface keeps the same voice', () {
      final lines = <String>{};
      for (final surface in CompanionSurface.values) {
        final reaction = junior(surface: surface)
            .notify(CompanionEvent.videoComplete, now: t0)
            .reaction!;
        lines.add(reaction.captionFor(NanoAppLocale.en));
      }
      expect(lines, hasLength(1));
    });

    test('changing surface changes the mode and clears the old reaction', () {
      final moved = junior(surface: CompanionSurface.home)
          .notify(CompanionEvent.home, now: t0)
          .withSurface(CompanionSurface.learning);
      expect(moved.isVisible, isFalse);
      expect(
        moved.modeFor(CompanionEvent.videoStart),
        CompanionMode.explorer,
      );
    });
  });

  group('story cards', () {
    test('are reserved for rare moments', () {
      expect(
        junior(surface: CompanionSurface.onboarding)
            .notify(CompanionEvent.appOpen, now: t0)
            .reaction!
            .presentation,
        CompanionPresentation.storyCard,
      );
      expect(
        junior(surface: CompanionSurface.learning)
            .notify(CompanionEvent.newWorld, now: t0)
            .reaction!
            .presentation,
        CompanionPresentation.storyCard,
      );
      expect(
        junior(surface: CompanionSurface.home)
            .notify(CompanionEvent.levelUp, now: t0)
            .reaction!
            .presentation,
        CompanionPresentation.storyCard,
      );
    });

    test('do not take over ordinary moments', () {
      for (final event in const [
        CompanionEvent.home,
        CompanionEvent.videoStart,
        CompanionEvent.quizQuestion,
        CompanionEvent.resultPassed,
        CompanionEvent.achievement,
      ]) {
        expect(
          junior(surface: CompanionSurface.quiz)
              .notify(event, now: t0)
              .reaction!
              .presentation,
          CompanionPresentation.inline,
          reason: '$event',
        );
      }
    });

    test('the same app open is inline outside onboarding', () {
      expect(
        junior(surface: CompanionSurface.home)
            .notify(CompanionEvent.appOpen, now: t0)
            .reaction!
            .presentation,
        CompanionPresentation.inline,
      );
    });
  });

  group('collisions', () {
    test('an outcome outranks ordinary guidance', () {
      final runtime = junior(surface: CompanionSurface.quiz).notifyFirstOf(
        const [CompanionEvent.quizQuestion, CompanionEvent.resultNeedsReview],
        now: t0,
      );
      expect(runtime.reaction!.event, CompanionEvent.resultNeedsReview);
    });

    test('a story card outranks ordinary guidance but not an outcome', () {
      final story = junior(surface: CompanionSurface.learning).notifyFirstOf(
        const [CompanionEvent.videoStart, CompanionEvent.newWorld],
        now: t0,
      );
      expect(story.reaction!.event, CompanionEvent.newWorld);

      final outcome = junior(surface: CompanionSurface.learning).notifyFirstOf(
        const [CompanionEvent.newWorld, CompanionEvent.levelUp],
        now: t0,
      );
      expect(outcome.reaction!.event, CompanionEvent.levelUp);
    });

    test('idle loses to anything else', () {
      final runtime = junior().notifyFirstOf(
        const [CompanionEvent.idle, CompanionEvent.home],
        now: t0,
      );
      expect(runtime.reaction!.event, CompanionEvent.home);
    });

    test('a tie keeps the order the caller listed', () {
      final runtime = junior(surface: CompanionSurface.learning).notifyFirstOf(
        const [CompanionEvent.videoStart, CompanionEvent.learningEntry],
        now: t0,
      );
      expect(runtime.reaction!.event, CompanionEvent.videoStart);
    });

    test('all-suppressed leaves the runtime alone', () {
      final senior = CompanionRuntime.forExperience(junior: false);
      final after = senior.notifyFirstOf(
        const [CompanionEvent.home, CompanionEvent.idle],
        now: t0,
      );
      expect(after.isVisible, isFalse);
      expect(after.shownThisSession, 0);
    });
  });

  group('session budget', () {
    test('rations ordinary appearances', () {
      var runtime = junior();
      var clock = t0;
      final events = [
        CompanionEvent.home,
        CompanionEvent.appOpen,
        CompanionEvent.learningEntry,
        CompanionEvent.videoStart,
        CompanionEvent.quizStart,
        CompanionEvent.quizQuestion,
        CompanionEvent.emptyState,
        CompanionEvent.returnFromInactivity,
      ];
      for (final event in events) {
        clock = clock.add(const Duration(minutes: 1));
        runtime = runtime.notify(event, now: clock);
      }
      expect(runtime.shownThisSession, CompanionRules.junior.maxPerSession);
      expect(
        runtime.skipReason(CompanionEvent.idle, clock),
        CompanionSkipReason.sessionBudget,
      );
    });

    test('senior is rationed harder than junior', () {
      expect(
        CompanionRules.senior.maxPerSession,
        lessThan(CompanionRules.junior.maxPerSession),
      );
    });

    test('an essential moment still gets through a spent budget', () {
      var runtime = junior();
      var clock = t0;
      for (final event in const [
        CompanionEvent.home,
        CompanionEvent.appOpen,
        CompanionEvent.learningEntry,
        CompanionEvent.videoStart,
        CompanionEvent.quizStart,
        CompanionEvent.quizQuestion,
      ]) {
        clock = clock.add(const Duration(minutes: 1));
        runtime = runtime.notify(event, now: clock);
      }
      final after = runtime.notify(CompanionEvent.resultPassed, now: clock);
      expect(after.reaction!.event, CompanionEvent.resultPassed);
      expect(after.shownThisSession, runtime.shownThisSession);
    });

    test('a new session starts the budget and the cooldowns over', () {
      var runtime = junior();
      var clock = t0;
      for (final event in const [
        CompanionEvent.home,
        CompanionEvent.appOpen,
        CompanionEvent.learningEntry,
        CompanionEvent.videoStart,
        CompanionEvent.quizStart,
        CompanionEvent.quizQuestion,
      ]) {
        clock = clock.add(const Duration(minutes: 1));
        runtime = runtime.notify(event, now: clock);
      }
      final fresh = runtime.newSession();
      expect(fresh.shownThisSession, 0);
      expect(fresh.isVisible, isFalse);
      expect(fresh.skipReason(CompanionEvent.home, clock), isNull);
    });
  });

  group('classroom mode', () {
    const classroom = AccessibilityPreferences(classroomMode: true);

    test('holds back ordinary guidance', () {
      final runtime = junior(preferences: classroom);
      expect(
        runtime.skipReason(CompanionEvent.home, t0),
        CompanionSkipReason.classroomMode,
      );
      expect(runtime.notify(CompanionEvent.home, now: t0).isVisible, isFalse);
    });

    test('still delivers an outcome, quietly and without motion', () {
      final reaction = junior(
        surface: CompanionSurface.quiz,
        preferences: classroom,
      ).notify(CompanionEvent.resultNeedsReview, now: t0).reaction!;
      expect(reaction.speaks, isFalse);
      expect(reaction.tier, CompanionAssetTier.staticArt);
      expect(reaction.showsCaption, isTrue);
    });

    test('does not spend the session budget on what it held back', () {
      final runtime = junior(preferences: classroom)
          .notify(CompanionEvent.home, now: t0)
          .notify(CompanionEvent.appOpen, now: t0);
      expect(runtime.shownThisSession, 0);
    });
  });

  test('skip reasons name the rule that fired', () {
    final senior = CompanionRuntime.forExperience(junior: false);
    expect(
      senior.skipReason(CompanionEvent.home, t0),
      CompanionSkipReason.quietForExperience,
    );

    final shown = CompanionRuntime.forExperience(junior: true)
        .notify(CompanionEvent.home, now: t0);
    expect(
      shown.skipReason(CompanionEvent.home, t0.add(const Duration(seconds: 1))),
      CompanionSkipReason.cooldown,
    );
    expect(
      shown.skipReason(CompanionEvent.home, t0.add(const Duration(minutes: 1))),
      isNull,
    );
  });
}
