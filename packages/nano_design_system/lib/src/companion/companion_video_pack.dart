/// Bundled companion reaction clips (CMP-04 tier-2).
///
/// Files live under [package] at `assets/companion/video/<clipId>.mp4`.
/// Missing files fall back to static poses at runtime.
abstract final class CompanionVideoPack {
  static const package = 'nano_design_system';

  static const clipIds = <String>[
    'intro_speaking',
    'home_greeting_speaking',
    'welcome_back_speaking',
    'guide_point',
    'listening',
    'correct_small_celebration',
    'gentle_retry_speaking',
    'lesson_complete_speaking',
    'quiz_complete_speaking',
    'level_up_speaking',
    'long_video_refresh_speaking',
  ];

  static String assetFor(String clipId) => 'assets/companion/video/$clipId.mp4';
}
