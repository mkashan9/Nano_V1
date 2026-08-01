/// A reaction authored once and reused wherever that reaction is reached
/// (MED-04, handbook 10.4).
///
/// What is missing here is the point. The client read side returns approved
/// footage and where it lives — never the direction, the prompt, the provider,
/// or the cost. Those are authoring detail: a caption is the product and a
/// learner needs it, a clip direction is a prompt and it stays in the
/// administration surface.
class ReactionClip {
  const ReactionClip({
    required this.slug,
    required this.mode,
    required this.mood,
    required this.slot,
    required this.version,
    required this.aspectRatio,
    required this.storageBucket,
    required this.storagePath,
    this.durationSeconds,
    this.contentType,
    this.byteSize,
    this.checksum,
  });

  /// The reaction this clip is of: one mode and one mood, joined by `_`.
  final String slug;

  /// Kept as strings rather than enums: the library is a server-side catalogue
  /// and may name a reaction this build of the app has never heard of. An
  /// unknown reaction is simply one no surface asks for, not a parse failure.
  final String mode;
  final String mood;

  /// Where the companion runtime looks the clip up, which is a
  /// `CompanionReaction.assetKey` — mode, mood, and the `shortClip` tier.
  final String slot;

  /// Which published direction this footage was made from. Older footage is not
  /// offered for newer direction, so the version travels with the clip.
  final int version;

  /// Framing is part of the direction. A clip written for a square inline stage
  /// is a different clip in a tall story card.
  final String aspectRatio;

  final String storageBucket;
  final String storagePath;
  final int? durationSeconds;
  final String? contentType;
  final int? byteSize;
  final String? checksum;

  /// Keyed by content, so regenerated footage is never served from a URL signed
  /// against the bytes it replaced.
  String get fileKey => checksum ?? storagePath;

  /// Whether there is something to play. Status and moderation are absent by
  /// design: the read side only returns ready, approved rows, so the one thing
  /// left to check is that a file is actually pointed at — and that it is
  /// footage rather than a still that landed in a clip slot.
  bool get isPlayable =>
      storageBucket.isNotEmpty &&
      storagePath.isNotEmpty &&
      (contentType == null || contentType!.startsWith('video/'));

  factory ReactionClip.fromRow(Map<String, dynamic> row) {
    return ReactionClip(
      slug: row['slug'] as String? ?? '',
      mode: row['mode'] as String? ?? '',
      mood: row['mood'] as String? ?? '',
      slot: row['slot'] as String? ?? '',
      version: (row['version'] as num?)?.toInt() ?? 1,
      aspectRatio: row['aspect_ratio'] as String? ?? '1:1',
      durationSeconds: (row['duration_seconds'] as num?)?.toInt(),
      storageBucket: row['storage_bucket'] as String? ?? '',
      storagePath: row['storage_path'] as String? ?? '',
      contentType: row['content_type'] as String?,
      byteSize: (row['byte_size'] as num?)?.toInt(),
      checksum: row['checksum'] as String?,
    );
  }
}

/// This reaction cannot be filmed as asked (MED-04).
///
/// Its own type because it is not a failure to retry: either the slug is not a
/// reaction at all, or the reaction has no published direction for the shape
/// that was asked for. A curator should be told which and asked to author it,
/// not offered the same button again.
class ReactionClipNotAuthorable implements Exception {
  const ReactionClipNotAuthorable(this.message);

  final String message;

  @override
  String toString() => 'ReactionClipNotAuthorable: $message';
}
