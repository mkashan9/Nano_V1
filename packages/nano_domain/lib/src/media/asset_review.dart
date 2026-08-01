import 'generated_asset.dart';

/// One row of the superadmin review queue (MED-05).
///
/// This is deliberately not [GeneratedAsset]. A reviewer needs things a learner
/// must never receive -- the prompt, the provider, what it cost -- and needs
/// them alongside the previous decision. Reusing the learner-facing model would
/// mean one class where half the fields are null depending on who is asking,
/// which is how a prompt eventually leaks into a child's client.
class AssetReviewItem {
  const AssetReviewItem({
    required this.id,
    required this.kind,
    required this.slot,
    required this.locale,
    required this.aspectRatio,
    required this.status,
    required this.moderation,
    this.prompt = '',
    this.promptVersion = '',
    this.providerId = '',
    this.feature = '',
    this.storageBucket,
    this.storagePath,
    this.contentType,
    this.byteSize,
    this.checksum,
    this.costMicros = 0,
    this.errorCode,
    this.requestedAt,
    this.completedAt,
    this.reviewedAt,
    this.reviewNote,
    this.reviewerName,
  });

  final String id;
  final GeneratedAssetKind kind;
  final String slot;
  final String locale;
  final String aspectRatio;
  final GeneratedAssetStatus status;
  final GeneratedAssetModeration moderation;

  /// Provenance. Admin-only, and the reason the queue is a separate read path.
  final String prompt;
  final String promptVersion;
  final String providerId;
  final String feature;

  final String? storageBucket;
  final String? storagePath;
  final String? contentType;
  final int? byteSize;
  final String? checksum;
  final int costMicros;
  final String? errorCode;
  final DateTime? requestedAt;
  final DateTime? completedAt;

  final DateTime? reviewedAt;
  final String? reviewNote;
  final String? reviewerName;

  /// Whether a decision can be made right now. A request that never produced
  /// bytes is in the queue so somebody can see it is stuck, not so they can
  /// publish it.
  bool get isDecidable => status == GeneratedAssetStatus.ready;

  bool get isPublished => moderation == GeneratedAssetModeration.approved;

  /// Whether there is a file to look at. A reviewer may preview an unapproved
  /// asset; a learner may not, and that difference is enforced by a storage
  /// policy rather than by this getter.
  bool get hasFile =>
      (storageBucket?.isNotEmpty ?? false) && (storagePath?.isNotEmpty ?? false);

  factory AssetReviewItem.fromRow(Map<String, dynamic> row) {
    return AssetReviewItem(
      id: row['id'] as String,
      kind: GeneratedAssetKind.fromName(row['kind'] as String? ?? 'image'),
      slot: row['slot'] as String? ?? '',
      locale: row['locale'] as String? ?? 'en',
      aspectRatio: row['aspect_ratio'] as String? ?? '1:1',
      status: GeneratedAssetStatus.fromName(
        row['status'] as String? ?? 'requested',
      ),
      moderation: GeneratedAssetModeration.fromName(
        row['moderation'] as String? ?? 'unreviewed',
      ),
      prompt: row['prompt'] as String? ?? '',
      promptVersion: row['prompt_version'] as String? ?? '',
      providerId: row['provider_id'] as String? ?? '',
      feature: row['feature'] as String? ?? '',
      storageBucket: row['storage_bucket'] as String?,
      storagePath: row['storage_path'] as String?,
      contentType: row['content_type'] as String?,
      byteSize: (row['byte_size'] as num?)?.toInt(),
      checksum: row['checksum'] as String?,
      costMicros: (row['cost_micros'] as num?)?.toInt() ?? 0,
      errorCode: row['error_code'] as String?,
      requestedAt: _time(row['requested_at']),
      completedAt: _time(row['completed_at']),
      reviewedAt: _time(row['reviewed_at']),
      reviewNote: row['review_note'] as String?,
      reviewerName: row['reviewer_name'] as String?,
    );
  }

  AssetReviewItem copyWith({
    GeneratedAssetModeration? moderation,
    DateTime? reviewedAt,
    String? reviewNote,
    String? reviewerName,
  }) {
    return AssetReviewItem(
      id: id,
      kind: kind,
      slot: slot,
      locale: locale,
      aspectRatio: aspectRatio,
      status: status,
      moderation: moderation ?? this.moderation,
      prompt: prompt,
      promptVersion: promptVersion,
      providerId: providerId,
      feature: feature,
      storageBucket: storageBucket,
      storagePath: storagePath,
      contentType: contentType,
      byteSize: byteSize,
      checksum: checksum,
      costMicros: costMicros,
      errorCode: errorCode,
      requestedAt: requestedAt,
      completedAt: completedAt,
      reviewedAt: reviewedAt ?? this.reviewedAt,
      reviewNote: reviewNote ?? this.reviewNote,
      reviewerName: reviewerName ?? this.reviewerName,
    );
  }
}

/// One decision, kept forever.
class AssetReviewEvent {
  const AssetReviewEvent({
    required this.id,
    required this.previousModeration,
    required this.decision,
    this.note = '',
    this.reviewerName,
    this.createdAt,
  });

  final String id;
  final GeneratedAssetModeration previousModeration;
  final GeneratedAssetModeration decision;
  final String note;
  final String? reviewerName;
  final DateTime? createdAt;

  factory AssetReviewEvent.fromRow(Map<String, dynamic> row) {
    return AssetReviewEvent(
      id: row['id'] as String,
      previousModeration: GeneratedAssetModeration.fromName(
        row['previous_moderation'] as String? ?? 'unreviewed',
      ),
      decision: GeneratedAssetModeration.fromName(
        row['decision'] as String? ?? 'unreviewed',
      ),
      note: row['note'] as String? ?? '',
      reviewerName: row['reviewer_name'] as String?,
      createdAt: _time(row['created_at']),
    );
  }
}

/// What a review call did. [unchanged] is not a failure: it means the decision
/// was already in force, which the caller should say plainly rather than
/// reporting a success that changed nothing.
class AssetReviewOutcome {
  const AssetReviewOutcome({
    required this.decision,
    required this.reviewed,
    required this.unchanged,
    this.assets = const [],
  });

  final GeneratedAssetModeration decision;
  final int reviewed;
  final int unchanged;
  final List<AssetReviewItem> assets;

  factory AssetReviewOutcome.fromJson(Map<String, dynamic> json) {
    final rows = (json['assets'] as List? ?? const [])
        .whereType<Map>()
        .map((row) => AssetReviewItem.fromRow(Map<String, dynamic>.from(row)))
        .toList(growable: false);
    return AssetReviewOutcome(
      decision: GeneratedAssetModeration.fromName(
        json['decision'] as String? ?? 'unreviewed',
      ),
      reviewed: (json['reviewed'] as num?)?.toInt() ?? 0,
      unchanged: (json['unchanged'] as num?)?.toInt() ?? 0,
      assets: rows,
    );
  }
}

/// The server refused a decision: not a reviewer, nothing to publish, a
/// rejection with no reason, or a slot a newer asset already fills.
///
/// Every one of these is something the reviewer can act on, so the message is
/// meant to be shown rather than swallowed and retried.
class AssetReviewRefused implements Exception {
  const AssetReviewRefused(this.message);

  final String message;

  @override
  String toString() => 'AssetReviewRefused: $message';
}

DateTime? _time(Object? value) => switch (value) {
      final String text => DateTime.tryParse(text),
      final DateTime time => time,
      _ => null,
    };
