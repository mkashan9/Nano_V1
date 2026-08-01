import '../companion/companion_reaction.dart';
import '../l10n/nano_app_locale.dart';

/// What a provider produced (MED-01).
enum GeneratedAssetKind {
  image,
  voice,
  video;

  static GeneratedAssetKind fromName(String value) =>
      GeneratedAssetKind.values.firstWhere(
        (kind) => kind.name == value,
        orElse: () => GeneratedAssetKind.image,
      );
}

/// Where a request has got to. Only [ready] has a file, and only an approved
/// [ready] asset is allowed anywhere near a learner.
enum GeneratedAssetStatus {
  requested,
  generating,
  ready,
  failed;

  static GeneratedAssetStatus fromName(String value) =>
      GeneratedAssetStatus.values.firstWhere(
        (status) => status.name == value,
        orElse: () => GeneratedAssetStatus.requested,
      );
}

/// Review outcome. MED-01 only ever reports [unreviewed]; MED-05 owns the rest.
enum GeneratedAssetModeration {
  unreviewed,
  approved,
  rejected;

  static GeneratedAssetModeration fromName(String value) =>
      GeneratedAssetModeration.values.firstWhere(
        (state) => state.name == value,
        orElse: () => GeneratedAssetModeration.unreviewed,
      );
}

/// One generated asset as the client sees it.
///
/// A learner's client only ever receives the published projection, so [prompt],
/// [providerId], and [costMicros] are null there. A superadmin tool reading the
/// authoring surface gets them filled in. The same class carries both rather than
/// two near-identical models, because the difference is a permission, not a shape.
class GeneratedAsset {
  const GeneratedAsset({
    required this.id,
    required this.kind,
    required this.slot,
    required this.locale,
    required this.aspectRatio,
    this.status = GeneratedAssetStatus.ready,
    this.moderation = GeneratedAssetModeration.unreviewed,
    this.storageBucket,
    this.storagePath,
    this.contentType,
    this.byteSize,
    this.checksum,
    this.prompt,
    this.promptVersion,
    this.promptHash,
    this.providerId,
    this.costMicros,
    this.attemptsCount = 0,
    this.errorCode,
    this.completedAt,
  });

  final String id;
  final GeneratedAssetKind kind;

  /// Where the asset is used; for a companion this is [CompanionReaction.assetKey].
  final String slot;
  final String locale;
  final String aspectRatio;
  final GeneratedAssetStatus status;
  final GeneratedAssetModeration moderation;
  final String? storageBucket;
  final String? storagePath;
  final String? contentType;
  final int? byteSize;
  final String? checksum;

  /// Authoring provenance. Absent on the learner-facing projection by design.
  final String? prompt;
  final String? promptVersion;
  final String? promptHash;
  final String? providerId;
  final int? costMicros;
  final int attemptsCount;
  final String? errorCode;
  final DateTime? completedAt;

  bool get isPlayable =>
      status == GeneratedAssetStatus.ready &&
      moderation == GeneratedAssetModeration.approved &&
      (storagePath?.isNotEmpty ?? false);

  factory GeneratedAsset.fromRow(Map<String, dynamic> row) {
    return GeneratedAsset(
      id: row['id'] as String,
      kind: GeneratedAssetKind.fromName(row['kind'] as String? ?? 'image'),
      slot: row['slot'] as String? ?? '',
      locale: row['locale'] as String? ?? 'en',
      aspectRatio: row['aspect_ratio'] as String? ?? '1:1',
      // The published projection carries no status column: everything it returns
      // is ready and approved, which is the only reason it is readable.
      status: GeneratedAssetStatus.fromName(
        row['status'] as String? ?? 'ready',
      ),
      moderation: GeneratedAssetModeration.fromName(
        row['moderation'] as String? ?? 'approved',
      ),
      storageBucket: row['storage_bucket'] as String?,
      storagePath: row['storage_path'] as String?,
      contentType: row['content_type'] as String?,
      byteSize: (row['byte_size'] as num?)?.toInt(),
      checksum: row['checksum'] as String?,
      prompt: row['prompt'] as String?,
      promptVersion: row['prompt_version'] as String?,
      promptHash: row['prompt_hash'] as String?,
      providerId: row['provider_id'] as String?,
      costMicros: (row['cost_micros'] as num?)?.toInt(),
      attemptsCount: (row['attempts_count'] as num?)?.toInt() ?? 0,
      errorCode: row['error_code'] as String?,
      completedAt: switch (row['completed_at']) {
        final String value => DateTime.tryParse(value),
        final DateTime value => value,
        _ => null,
      },
    );
  }
}

/// What a superadmin tool asks for. There is no client-side equivalent for
/// learners on purpose: generation is an administration workflow (handbook 10.5),
/// so nothing a child does can start one.
class GeneratedAssetRequest {
  const GeneratedAssetRequest({
    required this.kind,
    required this.slot,
    required this.prompt,
    required this.promptVersion,
    this.locale = NanoAppLocale.en,
    this.aspectRatio = '1:1',
    this.providerId,
    this.feature = 'companion',
    this.schoolId,
  });

  final GeneratedAssetKind kind;
  final String slot;
  final String prompt;
  final String promptVersion;
  final NanoAppLocale locale;
  final String aspectRatio;

  /// Null means the registry's default provider for [kind] decides.
  final String? providerId;

  /// Which part of the product is asking (MED-02). A budget dimension, not part
  /// of the reuse hash: two features asking for one output still pay once.
  final String feature;

  /// The school a request is made on behalf of, or null for platform-wide work.
  final String? schoolId;

  /// A companion request whose slot always matches what the runtime will look up.
  factory GeneratedAssetRequest.forReaction(
    CompanionReaction reaction, {
    required String prompt,
    required String promptVersion,
    NanoAppLocale locale = NanoAppLocale.en,
    String aspectRatio = '1:1',
    GeneratedAssetKind kind = GeneratedAssetKind.image,
    String? schoolId,
  }) {
    return GeneratedAssetRequest(
      kind: kind,
      slot: reaction.assetKey,
      prompt: prompt,
      promptVersion: promptVersion,
      locale: locale,
      aspectRatio: aspectRatio,
      schoolId: schoolId,
    );
  }

  Map<String, dynamic> toParams() => {
        'p_kind': kind.name,
        'p_slot': slot,
        'p_prompt': prompt,
        'p_prompt_version': promptVersion,
        'p_locale': locale.name,
        'p_aspect_ratio': aspectRatio,
        'p_provider_id': providerId,
        'p_feature': feature,
        'p_school_id': schoolId,
      };
}

/// The answer to a request. [reused] is the interesting part: it means an existing
/// output already covered this ask, so no provider was called and nothing was paid.
class GeneratedAssetOutcome {
  const GeneratedAssetOutcome({required this.reused, required this.asset});

  final bool reused;
  final GeneratedAsset asset;

  factory GeneratedAssetOutcome.fromJson(Map<String, dynamic> json) {
    return GeneratedAssetOutcome(
      reused: json['reused'] as bool? ?? false,
      asset: GeneratedAsset.fromRow(
        Map<String, dynamic>.from(json['asset'] as Map),
      ),
    );
  }
}
