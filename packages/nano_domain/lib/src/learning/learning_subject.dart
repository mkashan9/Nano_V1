/// Shared domain record rendered differently by Junior and Senior shells.
class LearningSubject {
  const LearningSubject({
    required this.id,
    required this.title,
    required this.progress,
    required this.worldColorValue,
    this.tag,
    this.estimatedMinutes,
    this.shortPrompt,
  });

  final String id;
  final String title;
  final double progress;
  final int worldColorValue;
  final String? tag;
  final int? estimatedMinutes;
  final String? shortPrompt;
}
