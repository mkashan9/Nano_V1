import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Access to authored narration (MED-03).
///
/// [published] is the learner-facing read: authored wording for one language, and
/// the recording of that exact wording when one exists. [request] is a curator
/// action that goes through the Edge Function, because that is the only place a
/// provider key lives.
abstract class NarrationRepository {
  Future<List<NarrationLine>> published({
    NanoAppLocale locale = NanoAppLocale.en,
    String? surface,
  });

  /// Record a published line. Returns the existing recording when the same line
  /// has already been recorded, in which case no provider was called.
  ///
  /// Throws [NarrationNotRecordable] when the line can never be recorded, and
  /// [GenerationQuotaExceeded] when today's allowance is spent.
  Future<GeneratedAssetOutcome> request(
    String slug, {
    NanoAppLocale locale,
    String? voiceId,
  });

  Future<String> signedUrl(NarrationAudio audio, {Duration expiresIn});
}

class FakeNarrationRepository implements NarrationRepository {
  FakeNarrationRepository({
    this.alwaysFail = false,
    this.recordable = true,
    List<NarrationLine>? seed,
  }) : _lines = [...?seed, if (seed == null) ..._defaultSeed];

  /// The catalog fetch fails. Nothing a learner sees may depend on it.
  final bool alwaysFail;

  /// False stands in for the server refusing to record — a personalised line, or a
  /// language nobody has authored.
  final bool recordable;

  final List<NarrationLine> _lines;
  var requestCount = 0;

  /// The seeded companion lines carry captions and no audio, which is exactly the
  /// state of a real project until a curator records and approves something.
  static final _defaultSeed = <NarrationLine>[
    const NarrationLine(
      slug: 'idle-1',
      locale: NanoAppLocale.en,
      text: 'Take your time.',
    ),
    const NarrationLine(
      slug: 'celebration-1',
      locale: NanoAppLocale.en,
      text: 'Nicely done!',
    ),
  ];

  @override
  Future<List<NarrationLine>> published({
    NanoAppLocale locale = NanoAppLocale.en,
    String? surface,
  }) async {
    if (alwaysFail) throw StateError('narration unavailable');
    return _lines
        .where((line) => line.locale == locale)
        .where((line) => surface == null || line.surface == surface)
        .toList(growable: false);
  }

  @override
  Future<GeneratedAssetOutcome> request(
    String slug, {
    NanoAppLocale locale = NanoAppLocale.en,
    String? voiceId,
  }) async {
    requestCount++;
    if (!recordable) {
      throw const NarrationNotRecordable(
        'A line with a placeholder cannot be pre-recorded.',
      );
    }
    final index = _lines.indexWhere(
      (line) => line.slug == slug && line.locale == locale,
    );
    if (index < 0) throw StateError('no published line $slug');
    final line = _lines[index];
    if (line.hasAudio) {
      return GeneratedAssetOutcome(reused: true, asset: _assetFor(line));
    }
    final recorded = NarrationLine(
      slug: line.slug,
      locale: line.locale,
      text: line.text,
      surface: line.surface,
      version: line.version,
      audio: NarrationAudio(
        storageBucket: 'generated-assets',
        storagePath:
            'voice/narration_${line.slug}/${line.locale.name}/hash.wav',
        contentType: 'audio/wav',
        byteSize: 4096,
        checksum: 'sha256:${line.slug}',
        voiceId: voiceId ?? CompanionVoiceProfile.defaultVoiceId,
      ),
    );
    _lines[index] = recorded;
    return GeneratedAssetOutcome(reused: false, asset: _assetFor(recorded));
  }

  @override
  Future<String> signedUrl(
    NarrationAudio audio, {
    Duration expiresIn = const Duration(minutes: 30),
  }) async {
    if (alwaysFail) throw StateError('signing unavailable');
    return 'https://fake.local/${audio.storagePath}?expires=${expiresIn.inSeconds}';
  }

  GeneratedAsset _assetFor(NarrationLine line) => GeneratedAsset(
    id: 'narration-${line.slug}-${line.locale.name}',
    kind: GeneratedAssetKind.voice,
    slot: 'narration_${line.slug}',
    locale: line.locale.name,
    aspectRatio: '1:1',
    status: GeneratedAssetStatus.ready,
    moderation: GeneratedAssetModeration.approved,
    storageBucket: line.audio?.storageBucket,
    storagePath: line.audio?.storagePath,
    contentType: line.audio?.contentType,
    byteSize: line.audio?.byteSize,
    checksum: line.audio?.checksum,
  );
}

class SupabaseNarrationRepository implements NarrationRepository {
  SupabaseNarrationRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<NarrationLine>> published({
    NanoAppLocale locale = NanoAppLocale.en,
    String? surface,
  }) async {
    // A function, not a table read: the authoring tables are admin-only and this
    // is the single projection a learner's client may see.
    final rows = await _client.rpc(
      'list_narration_lines',
      params: {'p_locale': locale.name, 'p_surface': surface},
    );
    return (rows as List)
        .map(
          (row) => NarrationLine.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  @override
  Future<GeneratedAssetOutcome> request(
    String slug, {
    NanoAppLocale locale = NanoAppLocale.en,
    String? voiceId,
  }) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'generate-asset',
        body: {
          // The words are not sent. The server reads them from the published
          // version, so a client cannot have the Guide say anything else.
          'narration_slug': slug,
          'locale': locale.name,
          'voice_id': ?voiceId,
        },
      );
    } on FunctionException catch (error) {
      final details = error.details;
      final body = details is Map ? details['error'] : null;
      final code = body is Map ? body['code'] : null;
      final message = body is Map ? body['message'] as String? : null;
      if (code == 'QUOTA_EXCEEDED') {
        throw GenerationQuotaExceeded(
          message ?? 'Daily generation limit reached.',
        );
      }
      if (code == 'NOT_RECORDABLE') {
        throw NarrationNotRecordable(
          message ?? 'That line cannot be recorded.',
        );
      }
      rethrow;
    }

    final data = response.data;
    if (data is! Map) {
      throw StateError('generate-asset returned ${response.status}');
    }
    return GeneratedAssetOutcome.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<String> signedUrl(
    NarrationAudio audio, {
    Duration expiresIn = const Duration(minutes: 30),
  }) async {
    return _client.storage
        .from(audio.storageBucket)
        .createSignedUrl(audio.storagePath, expiresIn.inSeconds);
  }
}
