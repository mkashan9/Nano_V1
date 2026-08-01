import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Access to the reusable reaction clip library (MED-04).
///
/// [published] is the learner-facing read: which reactions currently have an
/// approved clip, and where the file is — never the direction. [request] is a
/// curator action that goes through the Edge Function, because that is the only
/// place a provider key lives, and because the server (not the client) decides
/// what the footage is of.
abstract class ReactionClipRepository {
  Future<List<ReactionClip>> published();

  /// Film a published reaction. Returns the existing clip when the same shape
  /// has already been made, in which case no provider was called.
  ///
  /// Throws [ReactionClipNotAuthorable] when the reaction cannot be filmed as
  /// asked, and [GenerationQuotaExceeded] when today's allowance is spent.
  Future<GeneratedAssetOutcome> request(
    String slug, {
    String aspectRatio = '1:1',
  });

  Future<String> signedUrl(ReactionClip clip, {Duration expiresIn});
}

class FakeReactionClipRepository implements ReactionClipRepository {
  FakeReactionClipRepository({
    this.alwaysFail = false,
    this.authorable = true,
    List<ReactionClip>? seed,
  }) : _clips = [...?seed];

  /// The catalog fetch fails. Nothing a learner sees may depend on it.
  final bool alwaysFail;

  /// False stands in for the server refusing to film — a slug that is not a
  /// reaction, or a shape nobody has authored.
  final bool authorable;

  final List<ReactionClip> _clips;
  var requestCount = 0;

  /// A celebration clip that matches the slot the local manifest already
  /// reaches for. Empty by default, which is the resting state until a curator
  /// approves something.
  static final celebrationSeed = ReactionClip(
    slug: 'celebration_celebration',
    mode: 'celebration',
    mood: 'celebration',
    slot: 'celebration_celebration_shortClip',
    version: 1,
    aspectRatio: '1:1',
    durationSeconds: 3,
    storageBucket: 'generated-assets',
    storagePath: 'video/celebration_celebration_shortClip/en/hash.mp4',
    contentType: 'video/mp4',
    byteSize: 512000,
    checksum: 'sha256:seed-clip',
  );

  @override
  Future<List<ReactionClip>> published() async {
    if (alwaysFail) throw StateError('reaction clips unavailable');
    return _clips
        .where((clip) => clip.isPlayable)
        .toList(growable: false);
  }

  @override
  Future<GeneratedAssetOutcome> request(
    String slug, {
    String aspectRatio = '1:1',
  }) async {
    requestCount++;
    if (!authorable) {
      throw const ReactionClipNotAuthorable(
        'That reaction is not authored for this shape.',
      );
    }
    final index = _clips.indexWhere(
      (clip) => clip.slug == slug && clip.aspectRatio == aspectRatio,
    );
    if (index >= 0) {
      return GeneratedAssetOutcome(
        reused: true,
        asset: _assetFor(_clips[index]),
      );
    }
    final parts = slug.split('_');
    if (parts.length < 2 || parts.any((part) => part.isEmpty)) {
      throw ReactionClipNotAuthorable(
        'A reaction slug is exactly one mode and one mood, joined by _.',
      );
    }
    final mode = parts.first;
    final mood = parts.sublist(1).join('_');
    final created = ReactionClip(
      slug: slug,
      mode: mode,
      mood: mood,
      slot: '${slug}_shortClip',
      version: 1,
      aspectRatio: aspectRatio,
      durationSeconds: 3,
      storageBucket: 'generated-assets',
      storagePath: 'video/${slug}_shortClip/en/fake.mp4',
      contentType: 'video/mp4',
      byteSize: 4096,
      checksum: 'sha256:$slug',
    );
    _clips.add(created);
    return GeneratedAssetOutcome(reused: false, asset: _assetFor(created));
  }

  @override
  Future<String> signedUrl(
    ReactionClip clip, {
    Duration expiresIn = const Duration(minutes: 30),
  }) async {
    if (alwaysFail) throw StateError('signing unavailable');
    return 'https://fake.local/${clip.storagePath}?expires=${expiresIn.inSeconds}';
  }

  GeneratedAsset _assetFor(ReactionClip clip) => GeneratedAsset(
        id: 'clip-${clip.slug}-${clip.aspectRatio}',
        kind: GeneratedAssetKind.video,
        slot: clip.slot,
        locale: 'en',
        aspectRatio: clip.aspectRatio,
        status: GeneratedAssetStatus.ready,
        moderation: GeneratedAssetModeration.approved,
        storageBucket: clip.storageBucket,
        storagePath: clip.storagePath,
        contentType: clip.contentType,
        byteSize: clip.byteSize,
        checksum: clip.checksum,
      );
}

class SupabaseReactionClipRepository implements ReactionClipRepository {
  SupabaseReactionClipRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<ReactionClip>> published() async {
    // A function, not a table read: the authoring tables are admin-only and this
    // is the single projection a learner's client may see.
    final rows = await _client.rpc('list_reaction_clips');
    return (rows as List)
        .map(
          (row) => ReactionClip.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }

  @override
  Future<GeneratedAssetOutcome> request(
    String slug, {
    String aspectRatio = '1:1',
  }) async {
    final FunctionResponse response;
    try {
      response = await _client.functions.invoke(
        'generate-asset',
        body: {
          // The direction is not sent. The server reads it from the published
          // version, so a client cannot film anything but an authored reaction.
          'clip_slug': slug,
          'aspect_ratio': aspectRatio,
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
      if (code == 'NOT_AUTHORABLE' || code == 'NM009') {
        throw ReactionClipNotAuthorable(
          message ?? 'That reaction cannot be filmed as asked.',
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
    ReactionClip clip, {
    Duration expiresIn = const Duration(minutes: 30),
  }) async {
    return _client.storage
        .from(clip.storageBucket)
        .createSignedUrl(clip.storagePath, expiresIn.inSeconds);
  }
}
