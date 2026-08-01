import '../l10n/nano_app_locale.dart';

/// A recording of one line, as a client sees it (MED-03).
///
/// There is no status or moderation state here: the read side only returns files
/// that are ready and approved, so anything a client holds is playable. What is
/// carried instead is identity — bucket, path, checksum — because that is what a
/// signed URL is minted from and what tells a cache the file has changed.
class NarrationAudio {
  const NarrationAudio({
    required this.storageBucket,
    required this.storagePath,
    required this.contentType,
    required this.byteSize,
    this.checksum,
    this.voiceId,
  });

  final String storageBucket;
  final String storagePath;
  final String contentType;
  final int byteSize;
  final String? checksum;

  /// Which registered voice spoke it. Useful in a curator view; a learner's app
  /// never branches on it.
  final String? voiceId;

  /// Keyed by content, so a re-recorded line is never served from a cached URL.
  String get fileKey => checksum ?? storagePath;
}

/// This line will never have a recording (MED-03).
///
/// Its own type because it is not a failure to retry: the line has no wording in
/// this language, or it names the learner's companion and so belongs to captions
/// only. A curator should be told which, and asked to change the line rather than
/// to try again.
class NarrationNotRecordable implements Exception {
  const NarrationNotRecordable(this.message);

  final String message;

  @override
  String toString() => 'NarrationNotRecordable: $message';
}

/// An authored spoken line in one language (MED-03).
///
/// The text is the authority on the words, and [audio] is optional — a line with
/// no recording is the ordinary case, not a broken one. A caller that treats a
/// null [audio] as an error has misunderstood the feature.
class NarrationLine {
  const NarrationLine({
    required this.slug,
    required this.locale,
    required this.text,
    this.surface = 'companion',
    this.version = 1,
    this.audio,
  });

  /// Matches the local script id for companion lines, which is what lets a
  /// caption written into the app be checked against the words that were recorded.
  final String slug;

  final NanoAppLocale locale;
  final String text;
  final String surface;

  /// Which published wording this is. A recording of an earlier version is not
  /// offered for a later one, so the version travels with the line.
  final int version;

  final NarrationAudio? audio;

  bool get hasAudio => audio != null;

  factory NarrationLine.fromRow(Map<String, dynamic> row) {
    final path = row['storage_path'] as String?;
    return NarrationLine(
      slug: row['slug'] as String? ?? '',
      locale: NanoAppLocale.fromTag(row['locale'] as String?),
      // The server column is `line_text`: `text` is a type name in SQL and an
      // ambiguous column name next to the table it is read from.
      text: row['line_text'] as String? ?? '',
      surface: row['surface'] as String? ?? 'companion',
      version: (row['version'] as num?)?.toInt() ?? 1,
      audio: path == null || path.isEmpty
          ? null
          : NarrationAudio(
              storageBucket: row['storage_bucket'] as String? ?? 'generated-assets',
              storagePath: path,
              contentType: row['content_type'] as String? ?? 'audio/wav',
              byteSize: (row['byte_size'] as num?)?.toInt() ?? 0,
              checksum: row['checksum'] as String?,
              voiceId: row['voice_id'] as String?,
            ),
    );
  }
}
