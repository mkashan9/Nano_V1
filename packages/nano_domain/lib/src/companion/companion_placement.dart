import 'companion_mode.dart';

/// Where the companion sits on a surface (CMP-03).
///
/// Placement is the density decision made once, per surface and per experience,
/// instead of every screen choosing a companion size by eye.
enum CompanionPlacement {
  /// Junior's leading guidance: large, above the content it talks about.
  hero,

  /// Part of the flow it belongs to, at the page's own scale.
  inline,

  /// Senior's contextual note: small, beside content that already speaks.
  aside,

  /// This surface carries no companion at all.
  hidden;

  bool get isVisible => this != CompanionPlacement.hidden;
}

/// The placement table.
///
/// Junior leads with the companion on the surfaces where a learner needs a
/// starting point; Senior keeps it small everywhere and silent where the screen
/// is already dense. Social and settings carry none in either experience: one is
/// about other people, the other is a form.
abstract final class CompanionPlacementPolicy {
  static CompanionPlacement resolve({
    required CompanionSurface surface,
    required bool junior,
  }) {
    return switch (surface) {
      CompanionSurface.onboarding =>
        junior ? CompanionPlacement.hero : CompanionPlacement.aside,
      CompanionSurface.home =>
        junior ? CompanionPlacement.hero : CompanionPlacement.aside,
      CompanionSurface.learning =>
        junior ? CompanionPlacement.hero : CompanionPlacement.aside,
      CompanionSurface.quiz => CompanionPlacement.inline,
      CompanionSurface.progress =>
        junior ? CompanionPlacement.inline : CompanionPlacement.aside,
      CompanionSurface.game =>
        junior ? CompanionPlacement.inline : CompanionPlacement.aside,
      CompanionSurface.social || CompanionSurface.settings =>
        CompanionPlacement.hidden,
    };
  }
}
