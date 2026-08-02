/// GME-04 game asset + local storage state models.

enum GameLocalInstallStatus {
  notOnDevice,
  ready,
  updateAvailable,
  failed;

  String get wire => switch (this) {
        GameLocalInstallStatus.notOnDevice => 'not_on_device',
        GameLocalInstallStatus.ready => 'ready',
        GameLocalInstallStatus.updateAvailable => 'update_available',
        GameLocalInstallStatus.failed => 'failed',
      };
}

class GameAssetDescriptor {
  const GameAssetDescriptor({
    required this.assetId,
    required this.gameVersionId,
    required this.assetKey,
    required this.contentHash,
    required this.byteSize,
    this.sourceUri = '',
    this.sortOrder = 100,
  });

  final String assetId;
  final String gameVersionId;
  final String assetKey;
  final String contentHash;
  final int byteSize;
  final String sourceUri;
  final int sortOrder;

  factory GameAssetDescriptor.fromJson(Map<String, dynamic> json) {
    return GameAssetDescriptor(
      assetId: json['asset_id'] as String? ?? '',
      gameVersionId: json['game_version_id'] as String? ?? '',
      assetKey: json['asset_key'] as String? ?? '',
      contentHash: json['content_hash'] as String? ?? '',
      byteSize: (json['byte_size'] as num?)?.toInt() ?? 0,
      sourceUri: json['source_uri'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 100,
    );
  }
}

class GameAssetManifest {
  const GameAssetManifest({
    required this.gameVersionId,
    required this.assets,
    required this.totalBytes,
  });

  final String gameVersionId;
  final List<GameAssetDescriptor> assets;
  final int totalBytes;

  String get packHash {
    if (assets.isEmpty) return '';
    final sorted = [...assets]..sort((a, b) => a.assetKey.compareTo(b.assetKey));
    return sorted.map((a) => a.contentHash).join('|');
  }

  factory GameAssetManifest.fromJson(Map<String, dynamic> json) {
    final rows = json['assets'];
    return GameAssetManifest(
      gameVersionId: json['game_version_id'] as String? ?? '',
      assets: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            GameAssetDescriptor.fromJson(Map<String, dynamic>.from(row)),
      ],
      totalBytes: (json['total_bytes'] as num?)?.toInt() ?? 0,
    );
  }
}

/// Local pin for one game version (no jargon in UI layer).
class GameLocalInstall {
  const GameLocalInstall({
    required this.gameVersionId,
    required this.contentHash,
    required this.byteSize,
    required this.installedAt,
  });

  final String gameVersionId;
  final String contentHash;
  final int byteSize;
  final DateTime installedAt;
}

abstract final class GameInstallStateResolver {
  static GameLocalInstallStatus resolve({
    required GameAssetManifest? remote,
    required GameLocalInstall? local,
  }) {
    if (remote == null || remote.assets.isEmpty) {
      // Fixture hosts with no declared assets are treated as ready.
      return GameLocalInstallStatus.ready;
    }
    if (local == null) return GameLocalInstallStatus.notOnDevice;
    if (local.contentHash != remote.packHash) {
      return GameLocalInstallStatus.updateAvailable;
    }
    return GameLocalInstallStatus.ready;
  }
}
