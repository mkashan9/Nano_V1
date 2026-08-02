import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('fake local storage install update and free space', () async {
    final assets = FakeGameAssetRepository();
    final local = FakeGameLocalStorageRepository();
    final manifest = await assets.loadAssets('v-number');

    expect(await local.getInstall('v-number'), isNull);
    final pin = await local.install(manifest: manifest);
    expect(pin.contentHash, manifest.packHash);
    expect(await local.totalBytesUsed(), manifest.totalBytes);

    final newer = GameAssetManifest(
      gameVersionId: 'v-number',
      totalBytes: 300000,
      assets: [
        GameAssetDescriptor(
          assetId: 'a-number',
          gameVersionId: 'v-number',
          assetKey: 'pack',
          contentHash: 'sha256:number_rush_v2_fixture',
          byteSize: 300000,
        ),
      ],
    );
    expect(
      GameInstallStateResolver.resolve(
        remote: newer,
        local: await local.getInstall('v-number'),
      ),
      GameLocalInstallStatus.updateAvailable,
    );

    await local.install(manifest: newer);
    expect(
      GameInstallStateResolver.resolve(
        remote: newer,
        local: await local.getInstall('v-number'),
      ),
      GameLocalInstallStatus.ready,
    );

    await local.remove('v-number');
    expect(await local.totalBytesUsed(), 0);
  });
}
