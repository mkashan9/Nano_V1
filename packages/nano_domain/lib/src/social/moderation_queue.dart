/// SAFE-02 moderation queue models (admin). No peer user ids in client JSON.
import 'safety_report.dart';

enum ModerationResolution {
  dismiss,
  resolve,
  warn,
  suspend,
}

class ModerationQueueItem {
  const ModerationQueueItem({
    required this.id,
    required this.category,
    required this.status,
    required this.peerLabel,
    required this.reporterLabel,
    this.username,
    this.details,
    this.alsoBlocked = false,
    this.evidence = const {},
    this.resolutionAction,
    this.resolutionNote,
    this.createdAt,
    this.resolvedAt,
  });

  final String id;
  final ReportCategory category;
  final ReportStatus status;
  final String peerLabel;
  final String reporterLabel;
  final String? username;
  final String? details;
  final bool alsoBlocked;
  final Map<String, dynamic> evidence;
  final ModerationResolution? resolutionAction;
  final String? resolutionNote;
  final DateTime? createdAt;
  final DateTime? resolvedAt;

  factory ModerationQueueItem.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'] as String? ?? 'other';
    final statusRaw = (json['status'] as String? ?? 'open')
        .replaceAll('under_review', 'underReview');
    final actionRaw = json['resolution_action'] as String?;
    final evidenceRaw = json['evidence'];
    final created = json['created_at'];
    final resolved = json['resolved_at'];
    return ModerationQueueItem(
      id: json['id'] as String? ?? '',
      category: ReportCategory.values.firstWhere(
        (value) => value.name == categoryRaw,
        orElse: () => ReportCategory.other,
      ),
      status: ReportStatus.values.firstWhere(
        (value) => value.name == statusRaw,
        orElse: () => ReportStatus.open,
      ),
      peerLabel: json['peer_label'] as String? ?? 'Learner',
      reporterLabel: json['reporter_label'] as String? ?? 'Reporter',
      username: json['username'] as String?,
      details: json['details'] as String?,
      alsoBlocked: json['also_blocked'] as bool? ?? false,
      evidence: evidenceRaw is Map
          ? Map<String, dynamic>.from(evidenceRaw)
          : const {},
      resolutionAction: actionRaw == null
          ? null
          : ModerationResolution.values.firstWhere(
              (value) => value.name == actionRaw,
              orElse: () => ModerationResolution.resolve,
            ),
      resolutionNote: json['resolution_note'] as String?,
      createdAt: created is String ? DateTime.tryParse(created) : null,
      resolvedAt: resolved is String ? DateTime.tryParse(resolved) : null,
    );
  }
}
