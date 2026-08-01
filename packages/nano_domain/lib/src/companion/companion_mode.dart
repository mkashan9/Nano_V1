import 'companion_reaction.dart';

/// Where the learner is when the companion speaks.
///
/// The surface picks the *mode* (which Nori is on screen); the event picks the
/// *mood* (what Nori is doing). Keeping the two axes apart is what lets Quiz
/// Coach Nori celebrate without turning into Celebration Nori.
enum CompanionSurface {
  home,
  onboarding,
  learning,
  quiz,
  game,
  progress,
  social,
  settings,
}

/// Controlled variants of one identity (CMP-02).
///
/// Every mode shares the face, emblem, caption design, and entrance treatment;
/// only the accent and the framing change. There is no mode that is a different
/// character.
enum CompanionMode {
  guide,
  explorer,
  quizCoach,
  builder,
  celebration;

  static CompanionMode resolve({
    required CompanionSurface surface,
    required CompanionEvent event,
  }) {
    // A milestone reads as Celebration Nori wherever it happens.
    if (event == CompanionEvent.levelUp ||
        event == CompanionEvent.achievement) {
      return CompanionMode.celebration;
    }
    // A new world is an Explorer reveal, even from the home screen.
    if (event == CompanionEvent.newWorld) return CompanionMode.explorer;
    return switch (surface) {
      CompanionSurface.learning => CompanionMode.explorer,
      CompanionSurface.quiz => CompanionMode.quizCoach,
      CompanionSurface.game => CompanionMode.builder,
      CompanionSurface.home ||
      CompanionSurface.onboarding ||
      CompanionSurface.progress ||
      CompanionSurface.social ||
      CompanionSurface.settings =>
        CompanionMode.guide,
    };
  }
}

/// How much of the screen a reaction is allowed to take.
enum CompanionPresentation {
  /// The ordinary case: companion beside its caption, inside the page.
  inline,

  /// A rare framed moment (onboarding, a new world, a level milestone).
  storyCard,
}

/// Reaction rules: which moment wins, how often the companion may appear, and
/// when it must stay out of the way (CMP-02).
class CompanionRules {
  const CompanionRules({required this.maxPerSession});

  /// Junior tolerates more guidance, but still not unlimited.
  static const junior = CompanionRules(maxPerSession: 6);

  /// Senior expects to be left alone.
  static const senior = CompanionRules(maxPerSession: 3);

  /// Ordinary appearances allowed per session. Essential moments are exempt.
  final int maxPerSession;

  /// Story cards are reserved for moments worth interrupting for.
  CompanionPresentation presentationFor({
    required CompanionSurface surface,
    required CompanionEvent event,
  }) {
    final rare = event == CompanionEvent.newWorld ||
        event == CompanionEvent.levelUp ||
        (event == CompanionEvent.appOpen &&
            surface == CompanionSurface.onboarding);
    return rare ? CompanionPresentation.storyCard : CompanionPresentation.inline;
  }

  /// Only ordinary appearances are rationed.
  bool countsAgainstBudget(CompanionEvent event) => !event.isEssential;

  /// Higher wins when two moments arrive together.
  int priorityOf({
    required CompanionSurface surface,
    required CompanionEvent event,
  }) {
    if (event.isEssential) return 100;
    if (presentationFor(surface: surface, event: event) ==
        CompanionPresentation.storyCard) {
      return 80;
    }
    return event == CompanionEvent.idle ? 10 : 50;
  }
}
