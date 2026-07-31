import '../l10n/nano_app_locale.dart';
import '../l10n/nano_copy.dart';

/// What a refresh moment asks of the learner.
enum CheckpointKind {
  stretch,
  recall,
  ready;

  static CheckpointKind fromName(String? name) => switch (name) {
        'stretch' => CheckpointKind.stretch,
        'recall' => CheckpointKind.recall,
        _ => CheckpointKind.ready,
      };
}

/// How the learner answered a refresh moment.
enum CheckpointResponse {
  continued,
  stretched,
  answered,
  postponed;

  String get wireName => name;
}

/// A curator-owned refresh moment inside a long video.
class RefreshCheckpoint {
  const RefreshCheckpoint({
    required this.id,
    required this.topicVersionId,
    required this.atSeconds,
    required this.kind,
    required this.prompt,
    this.promptUr,
    this.isRequired = false,
  });

  factory RefreshCheckpoint.fromRow(Map<String, dynamic> row) {
    return RefreshCheckpoint(
      id: row['id'] as String,
      topicVersionId: row['topic_version_id'] as String,
      atSeconds: (row['at_seconds'] as num?)?.toInt() ?? 0,
      kind: CheckpointKind.fromName(row['kind'] as String?),
      prompt: (row['prompt'] as String?) ?? '',
      promptUr: row['prompt_ur'] as String?,
      isRequired: row['is_required'] as bool? ?? false,
    );
  }

  final String id;
  final String topicVersionId;
  final int atSeconds;
  final CheckpointKind kind;
  final String prompt;
  final String? promptUr;

  /// Required checkpoints interrupt even in Classroom Mode, and watch credit
  /// stops here on the server until the learner answers.
  final bool isRequired;

  String promptFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (promptUr?.isNotEmpty ?? false)
          ? promptUr!
          : prompt;

  String title(NanoCopy copy) => switch (kind) {
        CheckpointKind.stretch => copy.checkpointStretchTitle,
        CheckpointKind.recall => copy.checkpointRecallTitle,
        CheckpointKind.ready => copy.checkpointReadyTitle,
      };

  CheckpointResponse get defaultResponse => switch (kind) {
        CheckpointKind.stretch => CheckpointResponse.stretched,
        CheckpointKind.recall => CheckpointResponse.answered,
        CheckpointKind.ready => CheckpointResponse.continued,
      };
}

/// A chapter boundary. Protected chapters are never interrupted.
class VideoChapter {
  const VideoChapter({
    required this.atSeconds,
    required this.title,
    this.titleUr,
    this.isProtected = false,
  });

  factory VideoChapter.fromRow(Map<String, dynamic> row) {
    return VideoChapter(
      atSeconds: (row['at'] as num?)?.toInt() ?? 0,
      title: (row['title'] as String?) ?? '',
      titleUr: row['title_ur'] as String?,
      isProtected: row['protected'] as bool? ?? false,
    );
  }

  static List<VideoChapter> listFrom(Object? value) {
    if (value is! List) return const [];
    return [
      for (final row in value)
        if (row is Map) VideoChapter.fromRow(Map<String, dynamic>.from(row)),
    ]..sort((a, b) => a.atSeconds.compareTo(b.atSeconds));
  }

  final int atSeconds;
  final String title;
  final String? titleUr;
  final bool isProtected;

  String titleFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (titleUr?.isNotEmpty ?? false)
          ? titleUr!
          : title;
}

/// Whether the learner may drag ahead of what they have watched.
enum SeekPolicy {
  free,
  noSkipAhead;

  static SeekPolicy fromName(String? name) =>
      name == 'no_skip_ahead' ? SeekPolicy.noSkipAhead : SeekPolicy.free;

  bool get allowsSkippingAhead => this == SeekPolicy.free;
}

/// Decides which refresh moment to show, and where credit stops.
///
/// Handbook 10.4: never interrupt blindly, let learners silence optional
/// prompts, and keep required moments in place. `checkpoint_credit_gate` on the
/// server is the authority for credit; this mirrors it so the player can
/// explain itself before the next heartbeat lands.
abstract final class CheckpointPolicy {
  /// The server only generates checkpoints past this length.
  static const minimumVideoSeconds = 1800;

  /// How far past a checkpoint the prompt may still appear. Beyond this the
  /// learner has clearly moved on, so an optional prompt is dropped.
  static const graceSeconds = 20;

  /// Optional prompts are silenced in Classroom Mode or when the learner turns
  /// refresh prompts off. Required ones always survive.
  static bool shouldInterrupt(
    RefreshCheckpoint checkpoint, {
    required bool allowOptional,
  }) =>
      checkpoint.isRequired || allowOptional;

  /// The checkpoint due at [positionSeconds], if any.
  static RefreshCheckpoint? dueAt(
    List<RefreshCheckpoint> checkpoints,
    int positionSeconds, {
    required Set<String> answeredIds,
    required bool allowOptional,
  }) {
    RefreshCheckpoint? due;
    for (final checkpoint in checkpoints) {
      if (answeredIds.contains(checkpoint.id)) continue;
      if (!shouldInterrupt(checkpoint, allowOptional: allowOptional)) continue;
      if (positionSeconds < checkpoint.atSeconds) continue;
      final overshoot = positionSeconds - checkpoint.atSeconds;
      // A required checkpoint still stops a learner who scrubbed past it,
      // because credit is blocked there anyway.
      if (!checkpoint.isRequired && overshoot > graceSeconds) continue;
      if (due == null || checkpoint.atSeconds > due.atSeconds) {
        due = checkpoint;
      }
    }
    return due;
  }

  /// Where watch credit stops until required checkpoints are answered.
  static int creditGate(
    List<RefreshCheckpoint> checkpoints, {
    required Set<String> answeredIds,
    required int durationSeconds,
  }) {
    var gate = durationSeconds;
    for (final checkpoint in checkpoints) {
      if (!checkpoint.isRequired) continue;
      if (answeredIds.contains(checkpoint.id)) continue;
      if (checkpoint.atSeconds < gate) gate = checkpoint.atSeconds;
    }
    return gate;
  }

  /// The chapter containing [positionSeconds].
  static VideoChapter? chapterAt(
    List<VideoChapter> chapters,
    int positionSeconds,
  ) {
    VideoChapter? current;
    for (final chapter in chapters) {
      if (chapter.atSeconds <= positionSeconds) {
        current = chapter;
      } else {
        break;
      }
    }
    return current;
  }

  /// How far the scrubber may reach under [policy].
  static int seekCeiling({
    required SeekPolicy policy,
    required int watchedSeconds,
    required int durationSeconds,
  }) {
    if (policy.allowsSkippingAhead) return durationSeconds;
    final ceiling = watchedSeconds + 30;
    return ceiling > durationSeconds ? durationSeconds : ceiling;
  }
}
