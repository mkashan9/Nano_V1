import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/games/presentation/game_host_page.dart';

void main() {
  testWidgets('native Shape Sort host completes via shared bridge',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const game = CatalogGame(
      gameId: 'g-shape',
      versionId: 'v-shape',
      slug: 'shape_sort',
      category: GameCategory.world,
      titleEn: 'Shape Sort',
      summaryEn: 'Sort shapes',
      entryKind: GameEntryKind.flutter,
      entryRef: 'fixture://shape_sort',
      minGrade: 1,
      maxGrade: 3,
    );

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: GameHostPage(
            game: game,
            sessionRepository: FakeGameSessionRepository(),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.textContaining('Native Flutter host'), findsOneWidget);

    for (final shape in ['circle', 'square', 'triangle']) {
      await tester.tap(find.text('chip $shape'));
      await tester.pump();
      await tester.tap(find.text('bin $shape'));
      await tester.pump();
    }

    await tester.tap(find.text('Finish'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Verification comes later'), findsOneWidget);
  });
}
