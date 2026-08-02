import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('install resolver handles missing, ready, and update', () {
    const remote = GameAssetManifest(
      gameVersionId: 'v1',
      totalBytes: 10,
      assets: [
        GameAssetDescriptor(
          assetId: 'a1',
          gameVersionId: 'v1',
          assetKey: 'pack',
          contentHash: 'hash-a',
          byteSize: 10,
        ),
      ],
    );

    expect(
      GameInstallStateResolver.resolve(remote: remote, local: null),
      GameLocalInstallStatus.notOnDevice,
    );
    expect(
      GameInstallStateResolver.resolve(
        remote: remote,
        local: GameLocalInstall(
          gameVersionId: 'v1',
          contentHash: 'hash-a',
          byteSize: 10,
          installedAt: DateTime.utc(2026, 8, 1),
        ),
      ),
      GameLocalInstallStatus.ready,
    );
    expect(
      GameInstallStateResolver.resolve(
        remote: remote,
        local: GameLocalInstall(
          gameVersionId: 'v1',
          contentHash: 'hash-old',
          byteSize: 10,
          installedAt: DateTime.utc(2026, 8, 1),
        ),
      ),
      GameLocalInstallStatus.updateAvailable,
    );
    expect(
      GameInstallStateResolver.resolve(
        remote: const GameAssetManifest(
          gameVersionId: 'v1',
          assets: [],
          totalBytes: 0,
        ),
        local: null,
      ),
      GameLocalInstallStatus.ready,
    );
  });
}
