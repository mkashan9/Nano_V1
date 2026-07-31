import '../l10n/nano_copy.dart';
import 'learning_catalog.dart';

/// Why a start or progress write was refused.
enum TopicGateReason {
  locked,
  unavailable,
  notLearner,
  unknown;

  static TopicGateReason fromCode(String? code) => switch (code) {
        'NL001' => TopicGateReason.locked,
        'NL002' => TopicGateReason.unavailable,
        'NL003' => TopicGateReason.notLearner,
        _ => TopicGateReason.unknown,
      };
}

/// Thrown when the server refuses a topic write. The message is already
/// learner-facing; [reason] drives UI chrome (lock vs generic failure).
class TopicGateException implements Exception {
  const TopicGateException({
    required this.reason,
    required this.message,
    this.code,
  });

  final TopicGateReason reason;
  final String message;
  final String? code;

  @override
  String toString() => 'TopicGateException($code): $message';
}

/// What the primary action button on a topic detail should do.
enum TopicAction { start, resume, review, locked }

extension TopicActionX on TopicAction {
  String label(NanoCopy copy) => switch (this) {
        TopicAction.start => copy.startLabel,
        TopicAction.resume => copy.resumeLabel,
        TopicAction.review => copy.reviewLabel,
        TopicAction.locked => copy.lockedLabel,
      };

  bool get isEnabled => this != TopicAction.locked;
}

/// Progress row returned by start/save RPCs.
class TopicProgress {
  const TopicProgress({
    required this.userId,
    required this.topicVersionId,
    required this.status,
    required this.progress,
    required this.resumeSeconds,
    this.completedAt,
  });

  factory TopicProgress.fromRow(Map<String, dynamic> row) {
    final completedRaw = row['completed_at'] as String?;
    return TopicProgress(
      userId: row['user_id'] as String,
      topicVersionId: row['topic_version_id'] as String,
      status: TopicProgressStatus.fromName(row['status'] as String?),
      progress: (row['progress'] as num?)?.toDouble() ?? 0,
      resumeSeconds: (row['resume_seconds'] as num?)?.toInt() ?? 0,
      completedAt:
          completedRaw == null ? null : DateTime.tryParse(completedRaw),
    );
  }

  final String userId;
  final String topicVersionId;
  final TopicProgressStatus status;
  final double progress;
  final int resumeSeconds;
  final DateTime? completedAt;

  bool get isCompleted => status == TopicProgressStatus.completed;
}

/// Derives the primary action from a catalog topic. The client never invents
/// unlocks: a non-empty [CatalogTopic.blockingTitles] always wins.
abstract final class TopicActionPolicy {
  static TopicAction forTopic(CatalogTopic topic) {
    if (topic.isLocked) return TopicAction.locked;
    if (topic.isCompleted) return TopicAction.review;
    if (topic.canResume || topic.status == TopicProgressStatus.inProgress) {
      return TopicAction.resume;
    }
    return TopicAction.start;
  }

  /// Applies a server progress row onto a catalog topic so the UI can refresh
  /// without another catalog round trip. Lock state is left alone — only the
  /// server can change it.
  static CatalogTopic applyProgress(CatalogTopic topic, TopicProgress row) {
    return topic.copyWith(
      status: row.status,
      progress: row.progress,
      resumeSeconds: row.resumeSeconds,
    );
  }
}
