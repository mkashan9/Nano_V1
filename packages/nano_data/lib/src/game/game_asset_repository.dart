import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// GME-04 remote asset descriptors for an eligible version.
abstract class GameAssetRepository {
  Future<GameAssetManifest> loadAssets(String gameVersionId);
}

class FakeGameAssetRepository implements GameAssetRepository {
  FakeGameAssetRepository({Map<String, GameAssetManifest>? seed})
      : _seed = seed ??
            {
              'v-number': const GameAssetManifest(
                gameVersionId: 'v-number',
                totalBytes: 245760,
                assets: [
                  GameAssetDescriptor(
                    assetId: 'a-number',
                    gameVersionId: 'v-number',
                    assetKey: 'pack',
                    contentHash: 'sha256:number_rush_v1_fixture',
                    byteSize: 245760,
                    sourceUri: 'fixture://number_rush/pack',
                  ),
                ],
              ),
              'v-shape': const GameAssetManifest(
                gameVersionId: 'v-shape',
                totalBytes: 327680,
                assets: [
                  GameAssetDescriptor(
                    assetId: 'a-shape',
                    gameVersionId: 'v-shape',
                    assetKey: 'pack',
                    contentHash: 'sha256:shape_sort_v1_fixture',
                    byteSize: 327680,
                    sourceUri: 'fixture://shape_sort/pack',
                  ),
                ],
              ),
              'v-math-island': const GameAssetManifest(
                gameVersionId: 'v-math-island',
                totalBytes: 200000,
                assets: [
                  GameAssetDescriptor(
                    assetId: 'a-math-island',
                    gameVersionId: 'v-math-island',
                    assetKey: 'pack',
                    contentHash: 'sha256:math_island_v1',
                    byteSize: 200000,
                    sourceUri: 'fixture://math_island/pack',
                  ),
                ],
              ),
              'v-word-forest': const GameAssetManifest(
                gameVersionId: 'v-word-forest',
                totalBytes: 200000,
                assets: [
                  GameAssetDescriptor(
                    assetId: 'a-word-forest',
                    gameVersionId: 'v-word-forest',
                    assetKey: 'pack',
                    contentHash: 'sha256:word_forest_v1',
                    byteSize: 200000,
                    sourceUri: 'fixture://word_forest/pack',
                  ),
                ],
              ),
              'v-science-ocean': const GameAssetManifest(
                gameVersionId: 'v-science-ocean',
                totalBytes: 200000,
                assets: [
                  GameAssetDescriptor(
                    assetId: 'a-science-ocean',
                    gameVersionId: 'v-science-ocean',
                    assetKey: 'pack',
                    contentHash: 'sha256:science_ocean_v1',
                    byteSize: 200000,
                    sourceUri: 'fixture://science_ocean/pack',
                  ),
                ],
              ),
              'v-puzzle-castle': const GameAssetManifest(
                gameVersionId: 'v-puzzle-castle',
                totalBytes: 200000,
                assets: [
                  GameAssetDescriptor(
                    assetId: 'a-puzzle-castle',
                    gameVersionId: 'v-puzzle-castle',
                    assetKey: 'pack',
                    contentHash: 'sha256:puzzle_castle_v1',
                    byteSize: 200000,
                    sourceUri: 'fixture://puzzle_castle/pack',
                  ),
                ],
              ),
            };

  final Map<String, GameAssetManifest> _seed;

  @override
  Future<GameAssetManifest> loadAssets(String gameVersionId) async {
    return _seed[gameVersionId] ??
        GameAssetManifest(
          gameVersionId: gameVersionId,
          assets: const [],
          totalBytes: 0,
        );
  }
}

class SupabaseGameAssetRepository implements GameAssetRepository {
  SupabaseGameAssetRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<GameAssetManifest> loadAssets(String gameVersionId) async {
    final raw = await _client.rpc(
      'list_game_assets_for_learner',
      params: {'p_version_id': gameVersionId},
    );
    if (raw is! Map) throw StateError('Could not load game assets.');
    return GameAssetManifest.fromJson(Map<String, dynamic>.from(raw));
  }
}

/// Local install pins (fixture downloads are instantaneous marks).
abstract class GameLocalStorageRepository {
  Future<GameLocalInstall?> getInstall(String gameVersionId);

  Future<GameLocalInstall> install({
    required GameAssetManifest manifest,
  });

  Future<void> remove(String gameVersionId);

  Future<int> totalBytesUsed();
}

class FakeGameLocalStorageRepository implements GameLocalStorageRepository {
  FakeGameLocalStorageRepository({Map<String, GameLocalInstall>? seed})
      : _pins = {...?seed};

  final Map<String, GameLocalInstall> _pins;

  @override
  Future<GameLocalInstall?> getInstall(String gameVersionId) async =>
      _pins[gameVersionId];

  @override
  Future<GameLocalInstall> install({
    required GameAssetManifest manifest,
  }) async {
    final pin = GameLocalInstall(
      gameVersionId: manifest.gameVersionId,
      contentHash: manifest.packHash,
      byteSize: manifest.totalBytes,
      installedAt: DateTime.utc(2026, 8, 2, 12),
    );
    _pins[manifest.gameVersionId] = pin;
    return pin;
  }

  @override
  Future<void> remove(String gameVersionId) async {
    _pins.remove(gameVersionId);
  }

  @override
  Future<int> totalBytesUsed() async =>
      _pins.values.fold<int>(0, (sum, p) => sum + p.byteSize);
}
