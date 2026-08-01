import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// The superadmin publication workflow (MED-05).
///
/// This is the only way a generated asset becomes visible to a learner. There
/// is no learner-side counterpart and there never should be: MED-01 through
/// MED-04 produce assets that sit unreviewed until somebody with a name decides
/// otherwise.
abstract class AssetReviewRepository {
  /// The queue, most actionable first. Refused by the server for anyone who is
  /// not a platform admin, rather than returned empty -- an empty queue reads as
  /// "no work today", which is a dangerous thing to tell the wrong person.
  Future<List<AssetReviewItem>> queue({
    GeneratedAssetModeration? moderation,
    GeneratedAssetKind? kind,
    int limit,
  });

  /// Decide on one or many. All-or-nothing: if the server refuses any of them,
  /// none are published.
  ///
  /// Throws [AssetReviewRefused] when the decision cannot be made.
  Future<AssetReviewOutcome> decide(
    List<String> assetIds,
    GeneratedAssetModeration decision, {
    String note,
  });

  /// Every decision ever made about one asset, newest first.
  Future<List<AssetReviewEvent>> history(String assetId);

  /// A time-limited URL so a reviewer can see or hear the file before deciding.
  /// Works for unapproved assets, which is the whole point.
  Future<String> previewUrl(AssetReviewItem item, {Duration expiresIn});
}

class FakeAssetReviewRepository implements AssetReviewRepository {
  FakeAssetReviewRepository({List<AssetReviewItem>? seed, this.alwaysFail = false})
      : _items = [...?seed, if (seed == null) ..._defaultSeed];

  final bool alwaysFail;
  final List<AssetReviewItem> _items;
  final Map<String, List<AssetReviewEvent>> _history = {};
  var _eventCount = 0;

  static final _defaultSeed = <AssetReviewItem>[
    const AssetReviewItem(
      id: 'a0000000-0000-0000-0000-000000000001',
      kind: GeneratedAssetKind.image,
      slot: 'guide_greeting_staticArt',
      locale: 'en',
      aspectRatio: '1:1',
      status: GeneratedAssetStatus.ready,
      moderation: GeneratedAssetModeration.unreviewed,
      prompt: 'A small round friendly companion waving hello.',
      promptVersion: 'v1',
      providerId: 'pollinations_image',
      feature: 'companion',
      storageBucket: 'generated-assets',
      storagePath: 'image/guide_greeting_staticArt/en/hash.png',
      contentType: 'image/png',
      byteSize: 24576,
      checksum: 'sha256:seed-image',
    ),
    const AssetReviewItem(
      id: 'a0000000-0000-0000-0000-000000000002',
      kind: GeneratedAssetKind.video,
      slot: 'celebration_celebration_shortClip',
      locale: 'en',
      aspectRatio: '1:1',
      status: GeneratedAssetStatus.ready,
      moderation: GeneratedAssetModeration.unreviewed,
      prompt: 'The companion does a small celebratory hop.',
      promptVersion: 'v1',
      providerId: 'json2video_compose',
      feature: 'companion',
      storageBucket: 'generated-assets',
      storagePath: 'video/celebration_celebration_shortClip/en/hash.mp4',
      contentType: 'video/mp4',
      byteSize: 512000,
      checksum: 'sha256:seed-clip',
      costMicros: 120000,
    ),
    // A job that never produced bytes. It belongs in the queue so somebody can
    // see it is stuck, but it cannot be published.
    const AssetReviewItem(
      id: 'a0000000-0000-0000-0000-000000000003',
      kind: GeneratedAssetKind.voice,
      slot: 'guide_greeting_voice',
      locale: 'ur',
      aspectRatio: '1:1',
      status: GeneratedAssetStatus.failed,
      moderation: GeneratedAssetModeration.unreviewed,
      prompt: 'Assalam o alaikum.',
      promptVersion: 'v1',
      providerId: 'fish_audio_voice',
      feature: 'companion',
      errorCode: 'PROVIDER_UNCONFIGURED',
    ),
  ];

  @override
  Future<List<AssetReviewItem>> queue({
    GeneratedAssetModeration? moderation,
    GeneratedAssetKind? kind,
    int limit = 100,
  }) async {
    if (alwaysFail) throw const AssetReviewRefused('Review queue unavailable.');
    final rows = _items
        .where((item) => moderation == null || item.moderation == moderation)
        .where((item) => kind == null || item.kind == kind)
        .toList()
      // Same order as the server: what can be decided now comes first.
      ..sort((a, b) {
        final actionable = _rank(b).compareTo(_rank(a));
        if (actionable != 0) return actionable;
        return a.slot.compareTo(b.slot);
      });
    return rows.take(limit).toList(growable: false);
  }

  static int _rank(AssetReviewItem item) =>
      item.isDecidable && item.moderation == GeneratedAssetModeration.unreviewed
          ? 1
          : 0;

  @override
  Future<AssetReviewOutcome> decide(
    List<String> assetIds,
    GeneratedAssetModeration decision, {
    String note = '',
  }) async {
    if (alwaysFail) throw const AssetReviewRefused('Review unavailable.');
    if (assetIds.isEmpty) {
      throw const AssetReviewRefused('Name at least one asset to review.');
    }

    final trimmed = note.trim();
    if (decision == GeneratedAssetModeration.rejected && trimmed.isEmpty) {
      throw const AssetReviewRefused(
        'A rejection needs a reason so the next attempt can be better.',
      );
    }

    // Validate the whole batch before changing anything, so a refusal never
    // leaves half of it published.
    final targets = <AssetReviewItem>[];
    for (final id in assetIds.toSet()) {
      final index = _items.indexWhere((item) => item.id == id);
      if (index < 0) throw const AssetReviewRefused('That asset does not exist.');
      final item = _items[index];
      if (decision == GeneratedAssetModeration.approved && !item.isDecidable) {
        throw const AssetReviewRefused('Only a ready asset can be approved.');
      }
      targets.add(item);
    }

    var reviewed = 0;
    var unchanged = 0;
    final touched = <AssetReviewItem>[];
    for (final item in targets) {
      if (item.moderation == decision) {
        unchanged++;
        touched.add(item);
        continue;
      }
      final updated = item.copyWith(
        moderation: decision,
        reviewedAt: DateTime.now().toUtc(),
        reviewNote: trimmed.isEmpty ? null : trimmed,
        reviewerName: 'Platform Admin',
      );
      _items[_items.indexWhere((row) => row.id == item.id)] = updated;
      _history.putIfAbsent(item.id, () => []).insert(
            0,
            AssetReviewEvent(
              id: 'event-${++_eventCount}',
              previousModeration: item.moderation,
              decision: decision,
              note: trimmed,
              reviewerName: 'Platform Admin',
              createdAt: DateTime.now().toUtc(),
            ),
          );
      reviewed++;
      touched.add(updated);
    }

    return AssetReviewOutcome(
      decision: decision,
      reviewed: reviewed,
      unchanged: unchanged,
      assets: touched,
    );
  }

  @override
  Future<List<AssetReviewEvent>> history(String assetId) async {
    if (alwaysFail) throw const AssetReviewRefused('History unavailable.');
    return List.unmodifiable(_history[assetId] ?? const []);
  }

  @override
  Future<String> previewUrl(
    AssetReviewItem item, {
    Duration expiresIn = const Duration(minutes: 10),
  }) async {
    if (alwaysFail) throw const AssetReviewRefused('Preview unavailable.');
    if (!item.hasFile) {
      throw const AssetReviewRefused('That asset has no file yet.');
    }
    return 'https://fake.local/${item.storagePath}?expires=${expiresIn.inSeconds}';
  }
}

class SupabaseAssetReviewRepository implements AssetReviewRepository {
  SupabaseAssetReviewRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<AssetReviewItem>> queue({
    GeneratedAssetModeration? moderation,
    GeneratedAssetKind? kind,
    int limit = 100,
  }) async {
    return _guard(() async {
      final rows = await _client.rpc(
        'list_assets_for_review',
        params: {
          'p_moderation': moderation?.name,
          'p_kind': kind?.name,
          'p_limit': limit,
        },
      );
      return (rows as List)
          .map(
            (row) =>
                AssetReviewItem.fromRow(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<AssetReviewOutcome> decide(
    List<String> assetIds,
    GeneratedAssetModeration decision, {
    String note = '',
  }) async {
    return _guard(() async {
      final json = await _client.rpc(
        'review_generated_assets',
        params: {
          'p_asset_ids': assetIds,
          'p_decision': decision.name,
          'p_note': note,
        },
      );
      return AssetReviewOutcome.fromJson(Map<String, dynamic>.from(json as Map));
    });
  }

  @override
  Future<List<AssetReviewEvent>> history(String assetId) async {
    return _guard(() async {
      final rows = await _client.rpc(
        'asset_review_history',
        params: {'p_asset_id': assetId},
      );
      return (rows as List)
          .map(
            (row) =>
                AssetReviewEvent.fromRow(Map<String, dynamic>.from(row as Map)),
          )
          .toList(growable: false);
    });
  }

  @override
  Future<String> previewUrl(
    AssetReviewItem item, {
    Duration expiresIn = const Duration(minutes: 10),
  }) async {
    final bucket = item.storageBucket;
    final path = item.storagePath;
    if (bucket == null || path == null) {
      throw const AssetReviewRefused('That asset has no file yet.');
    }
    // Readable because MED-05 gives platform admins their own storage read
    // policy; the same call as a learner would fail for an unapproved object.
    return _client.storage.from(bucket).createSignedUrl(path, expiresIn.inSeconds);
  }

  /// NM010 is the module's single refusal code, and every one of its messages is
  /// written to be shown to the reviewer, so it becomes a named answer rather
  /// than a raw Postgres error.
  Future<T> _guard<T>(Future<T> Function() run) async {
    try {
      return await run();
    } on PostgrestException catch (error) {
      if (error.code == 'NM010') {
        throw AssetReviewRefused(error.message);
      }
      rethrow;
    }
  }
}
