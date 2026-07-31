import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('ready and banners do not block content', () {
    expect(const NanoViewReady().blocksContent, isFalse);
    expect(const NanoViewOffline().blocksContent, isFalse);
    expect(const NanoViewSyncing().blocksContent, isFalse);
  });

  test('blocking states cover error empty suspended maintenance access', () {
    expect(const NanoViewLoading().blocksContent, isTrue);
    expect(const NanoViewEmpty().blocksContent, isTrue);
    expect(const NanoViewError().blocksContent, isTrue);
    expect(const NanoViewSuspended().blocksContent, isTrue);
    expect(const NanoViewMaintenance().blocksContent, isTrue);
    expect(const NanoViewPermissionDenied().blocksContent, isTrue);
    expect(const NanoViewFeatureDisabled().blocksContent, isTrue);
  });
}
