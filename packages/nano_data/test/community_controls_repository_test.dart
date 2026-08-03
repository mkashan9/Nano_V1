import 'package:nano_data/nano_data.dart';
import 'package:test/test.dart';

void main() {
  test('FakeCommunityControlsRepository defaults platform ON', () async {
    final repo = FakeCommunityControlsRepository();
    expect((await repo.loadPlatformPolicy()).communitiesEnabled, isTrue);
    expect((await repo.myEntitlements()).communitiesEnabled, isTrue);

    final off = await repo.savePlatformPolicy(enabled: false);
    expect(off.communitiesEnabled, isFalse);
    expect((await repo.myEntitlements()).communitiesEnabled, isFalse);
  });
}
