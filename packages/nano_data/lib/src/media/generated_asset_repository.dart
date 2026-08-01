import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Access to generated assets (MED-01).
///
/// Two audiences, deliberately separate methods: [listPublished] is what a
/// learner's client may read, and [listForReview] plus [request] belong to an
/// administration workflow. No method here takes or returns a provider key —
/// generation happens inside the Edge Function, which is the only place a key
/// exists.
abstract class GeneratedAssetRepository {
  /// Ready and approved assets, file identity only.
  Future<List<GeneratedAsset>> listPublished({
    GeneratedAssetKind? kind,
    NanoAppLocale? locale,
  });

  /// Everything, with provenance. Refused by the server for anyone but a
  /// platform admin.
  Future<List<GeneratedAsset>> listForReview();

  /// Ask for an asset. Returns the existing one when the same ask already exists,
  /// in which case no provider was called.
  Future<GeneratedAssetOutcome> request(GeneratedAssetRequest request);

  /// A time-limited URL for a private file, for review and for playback.
  Future<String> signedUrl(GeneratedAsset asset, {Duration expiresIn});
}

class FakeGeneratedAssetRepository implements GeneratedAssetRepository {
  FakeGeneratedAssetRepository({
    this.alwaysFail = false,
    this.providerUnconfigured = false,
    List<GeneratedAsset>? seed,
  }) : _items = [...?seed, if (seed == null) ..._defaultSeed];

  final bool alwaysFail;

  /// Mimics the voice and video path before MED-03 and MED-04 pick providers:
  /// the request is recorded and fails, and the caller falls back to local art.
  final bool providerUnconfigured;

  final List<GeneratedAsset> _items;
  var requestCount = 0;

  static final _defaultSeed = <GeneratedAsset>[
    GeneratedAsset(
      id: '90000000-0000-0000-0000-000000000001',
      kind: GeneratedAssetKind.image,
      slot: 'guide_greeting_staticArt',
      locale: 'en',
      aspectRatio: '1:1',
      moderation: GeneratedAssetModeration.approved,
      storageBucket: 'generated-assets',
      storagePath: 'image/guide_greeting_staticArt/en/hash.png',
      contentType: 'image/png',
      byteSize: 24576,
      checksum: 'sha256:seed-image',
      completedAt: DateTime.utc(2026, 8, 1),
    ),
    GeneratedAsset(
      id: '90000000-0000-0000-0000-000000000002',
      kind: GeneratedAssetKind.video,
      slot: 'celebration_celebration_shortClip',
      locale: 'en',
      aspectRatio: '1:1',
      moderation: GeneratedAssetModeration.approved,
      storageBucket: 'generated-assets',
      storagePath: 'video/celebration_celebration_shortClip/en/hash.mp4',
      contentType: 'video/mp4',
      byteSize: 512000,
      checksum: 'sha256:seed-clip',
      completedAt: DateTime.utc(2026, 8, 1),
    ),
  ];

  @override
  Future<List<GeneratedAsset>> listPublished({
    GeneratedAssetKind? kind,
    NanoAppLocale? locale,
  }) async {
    if (alwaysFail) throw StateError('generated assets unavailable');
    return _items
        .where((asset) => asset.isPlayable)
        .where((asset) => kind == null || asset.kind == kind)
        .where((asset) => locale == null || asset.locale == locale.name)
        .toList(growable: false);
  }

  @override
  Future<List<GeneratedAsset>> listForReview() async {
    if (alwaysFail) throw StateError('generated assets unavailable');
    return List.unmodifiable(_items);
  }

  @override
  Future<GeneratedAssetOutcome> request(GeneratedAssetRequest request) async {
    if (alwaysFail) throw StateError('generation unavailable');
    requestCount++;

    final existing = _items.firstWhere(
      (asset) =>
          asset.slot == request.slot &&
          asset.locale == request.locale.name &&
          asset.kind == request.kind &&
          asset.aspectRatio == request.aspectRatio &&
          asset.status != GeneratedAssetStatus.failed,
      orElse: () => _missing,
    );
    if (existing != _missing) {
      return GeneratedAssetOutcome(reused: true, asset: existing);
    }

    final created = GeneratedAsset(
      id: 'fake-${_items.length + 1}',
      kind: request.kind,
      slot: request.slot,
      locale: request.locale.name,
      aspectRatio: request.aspectRatio,
      status: providerUnconfigured
          ? GeneratedAssetStatus.failed
          : GeneratedAssetStatus.ready,
      moderation: GeneratedAssetModeration.unreviewed,
      storageBucket: providerUnconfigured ? null : 'generated-assets',
      storagePath: providerUnconfigured
          ? null
          : '${request.kind.name}/${request.slot}/${request.locale.name}/fake',
      prompt: request.prompt,
      promptVersion: request.promptVersion,
      providerId: request.providerId ?? _defaultProviderFor(request.kind),
      errorCode: providerUnconfigured ? 'PROVIDER_UNCONFIGURED' : null,
      attemptsCount: 1,
    );
    _items.add(created);
    return GeneratedAssetOutcome(reused: false, asset: created);
  }

  @override
  Future<String> signedUrl(
    GeneratedAsset asset, {
    Duration expiresIn = const Duration(minutes: 10),
  }) async {
    if (alwaysFail) throw StateError('signing unavailable');
    return 'https://fake.local/${asset.storagePath}?expires=${expiresIn.inSeconds}';
  }

  static String _defaultProviderFor(GeneratedAssetKind kind) => switch (kind) {
        GeneratedAssetKind.image => 'pollinations_image',
        GeneratedAssetKind.voice => 'configured_voice',
        GeneratedAssetKind.video => 'configured_video',
      };

  static const _missing = GeneratedAsset(
    id: '',
    kind: GeneratedAssetKind.image,
    slot: '',
    locale: 'en',
    aspectRatio: '1:1',
  );
}

class SupabaseGeneratedAssetRepository implements GeneratedAssetRepository {
  SupabaseGeneratedAssetRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<GeneratedAsset>> listPublished({
    GeneratedAssetKind? kind,
    NanoAppLocale? locale,
  }) async {
    // A function rather than a table read: the asset table is admin-only, and this
    // is the one projection a client is allowed to see.
    final rows = await _client.rpc(
      'list_generated_assets',
      params: {
        'p_kind': kind?.name,
        'p_locale': locale?.name,
        'p_slot': null,
      },
    );
    return _mapRows(rows);
  }

  @override
  Future<List<GeneratedAsset>> listForReview() async {
    final rows = await _client
        .from('generated_assets')
        .select()
        .order('requested_at', ascending: false);
    return _mapRows(rows);
  }

  @override
  Future<GeneratedAssetOutcome> request(GeneratedAssetRequest request) async {
    // The Edge Function is the only caller of a provider, so a client asks it
    // rather than asking a provider. It forwards the caller's token, which is what
    // keeps the permission check on the server.
    final response = await _client.functions.invoke(
      'generate-asset',
      body: {
        'kind': request.kind.name,
        'slot': request.slot,
        'prompt': request.prompt,
        'prompt_version': request.promptVersion,
        'locale': request.locale.name,
        'aspect_ratio': request.aspectRatio,
        if (request.providerId != null) 'provider_id': request.providerId,
      },
    );
    final data = response.data;
    if (data is! Map) {
      throw StateError('generate-asset returned ${response.status}');
    }
    return GeneratedAssetOutcome.fromJson(Map<String, dynamic>.from(data));
  }

  @override
  Future<String> signedUrl(
    GeneratedAsset asset, {
    Duration expiresIn = const Duration(minutes: 10),
  }) async {
    final bucket = asset.storageBucket;
    final path = asset.storagePath;
    if (bucket == null || path == null) {
      throw StateError('asset ${asset.id} has no file');
    }
    return _client.storage.from(bucket).createSignedUrl(path, expiresIn.inSeconds);
  }

  List<GeneratedAsset> _mapRows(dynamic rows) {
    return (rows as List)
        .map(
          (row) => GeneratedAsset.fromRow(Map<String, dynamic>.from(row as Map)),
        )
        .toList(growable: false);
  }
}
