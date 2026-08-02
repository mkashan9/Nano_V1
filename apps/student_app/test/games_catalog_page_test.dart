import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/games/presentation/games_catalog_page.dart';

void main() {
  testWidgets('save then play fixture game from catalog', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final local = FakeGameLocalStorageRepository();
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: GamesCatalogPage(
            repository: FakeGameCatalogRepository(),
            sessionRepository: FakeGameSessionRepository(),
            assetRepository: FakeGameAssetRepository(),
            localStorageRepository: local,
            gradeLevel: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Number Rush'), findsOneWidget);
    expect(find.textContaining('Not on this device'), findsWidgets);
    expect(find.text('Play'), findsNothing);

    await tester.tap(find.text('Save').first);
    await tester.pumpAndSettle();

    expect(find.textContaining('Ready to play'), findsWidgets);
    expect(find.textContaining('Saved:'), findsOneWidget);

    await tester.tap(find.text('Play').first);
    await tester.pumpAndSettle();
    expect(find.text('Tap to score'), findsOneWidget);
  });

  testWidgets('free space returns game to not on device', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1600));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final local = FakeGameLocalStorageRepository(
      seed: {
        'v-number': GameLocalInstall(
          gameVersionId: 'v-number',
          contentHash: 'sha256:number_rush_v1_fixture',
          byteSize: 245760,
          installedAt: DateTime.utc(2026, 8, 1),
        ),
      },
    );

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: GamesCatalogPage(
            repository: FakeGameCatalogRepository(),
            assetRepository: FakeGameAssetRepository(),
            localStorageRepository: local,
            gradeLevel: 3,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Ready to play'), findsWidgets);
    await tester.tap(find.text('Free space').first);
    await tester.pumpAndSettle();
    expect(find.textContaining('Not on this device'), findsWidgets);
  });
}
