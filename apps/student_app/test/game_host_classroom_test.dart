import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/games/presentation/game_host_page.dart';

void main() {
  testWidgets('host classroom toggle quiets the fixture surface',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    const game = CatalogGame(
      gameId: 'g-number',
      versionId: 'v-number',
      slug: 'number_rush',
      category: GameCategory.practice,
      titleEn: 'Number Rush',
      summaryEn: 'Count',
      entryRef: 'fixture://number_rush',
      minGrade: 1,
      maxGrade: 5,
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

    expect(find.text('Classroom mode'), findsOneWidget);
    expect(find.textContaining('Fixture host · score'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();
    expect(find.text('Sound and haptics stay quiet.'), findsOneWidget);
    expect(find.textContaining('Fixture host · quiet'), findsOneWidget);
  });
}
