/// SAFE-01 user report models. Peer user ids never appear in client JSON.
enum ReportCategory {
  harassment,
  spam,
  inappropriate,
  impersonation,
  other,
}

enum ReportStatus {
  open,
  underReview,
  resolved,
  dismissed,
}

class SafetyReport {
  const SafetyReport({
    required this.id,
    required this.category,
    required this.status,
    required this.peerLabel,
    this.username,
    this.details,
    this.alsoBlocked = false,
    this.createdAt,
  });

  final String id;
  final ReportCategory category;
  final ReportStatus status;
  final String peerLabel;
  final String? username;
  final String? details;
  final bool alsoBlocked;
  final DateTime? createdAt;

  factory SafetyReport.fromJson(Map<String, dynamic> json) {
    final categoryRaw = json['category'] as String? ?? 'other';
    final statusRaw = (json['status'] as String? ?? 'open')
        .replaceAll('under_review', 'underReview');
    final created = json['created_at'];
    return SafetyReport(
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
      username: json['username'] as String?,
      details: json['details'] as String?,
      alsoBlocked: json['also_blocked'] as bool? ?? false,
      createdAt: created is String ? DateTime.tryParse(created) : null,
    );
  }
}

class ReportDraft {
  const ReportDraft({
    required this.category,
    this.details,
    this.alsoBlock = false,
  });

  final ReportCategory category;
  final String? details;
  final bool alsoBlock;

  String get categoryWire => category.name;
}
