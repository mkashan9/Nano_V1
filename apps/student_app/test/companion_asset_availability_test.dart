import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

/// MED-02: the app asks once whether generated clips exist, and the answer never
/// decides whether the app works.
void main() {
  const config = EnvironmentConfig(
    environment: NanoEnvironment.development,
    supabaseUrl: '',
    supabaseAnonKey: '',
    featureFlags: {'diagnostics': true},
  );

  Future<void> pumpApp(
    WidgetTester tester, {
    GeneratedAssetRepository? assetRepository,
  }) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(
      NanoStudentApp(config: config, assetRepository: assetRepository),
    );
    await tester.pumpAndSettle();
  }

  /// The controller the running app is actually using.
  CompanionController companionOf(WidgetTester tester) {
    final scope = tester.widget<NanoCompanionScope>(
      find.byType(NanoCompanionScope).first,
    );
    return scope.notifier!;
  }

  GeneratedAsset clip() => GeneratedAsset(
        id: 'clip-1',
        kind: GeneratedAssetKind.video,
        slot: 'celebration_celebration_shortClip',
        locale: 'en',
        aspectRatio: '1:1',
        moderation: GeneratedAssetModeration.approved,
        storageBucket: 'generated-assets',
        storagePath: 'video/celebration/en/hash.mp4',
        contentType: 'video/mp4',
        byteSize: 4096,
        checksum: 'sha256:clip',
        completedAt: DateTime.utc(2026, 8, 1),
      );

  testWidgets('with nothing published the companion stays on local art',
      (tester) async {
    await pumpApp(
      tester,
      assetRepository: FakeGeneratedAssetRepository(seed: const []),
    );

    expect(companionOf(tester).clipsAvailable, isFalse);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a published clip is picked up without disturbing the screen',
      (tester) async {
    await pumpApp(
      tester,
      assetRepository: FakeGeneratedAssetRepository(seed: [clip()]),
    );

    expect(companionOf(tester).clipsAvailable, isTrue);
    expect(
      companionOf(tester).clipSlots,
      contains('celebration_celebration_shortClip'),
    );
    // The catalog arrived behind a screen that was already up, and nothing on it
    // was interrupted to make room for the news.
    expect(companionOf(tester).reaction, isNotNull);
    expect(tester.takeException(), isNull);
  });

  testWidgets('a failing catalog is not an error the learner ever sees',
      (tester) async {
    await pumpApp(
      tester,
      assetRepository: FakeGeneratedAssetRepository(alwaysFail: true),
    );

    expect(companionOf(tester).clipsAvailable, isFalse);
    expect(tester.takeException(), isNull);
  });
}
