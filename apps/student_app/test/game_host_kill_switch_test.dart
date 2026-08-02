import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/games/presentation/game_host_page.dart';

void main() {
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

  testWidgets('disabled version shows kill copy on start', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: GameHostPage(
            game: game,
            sessionRepository: FakeGameSessionRepository(
              disabledVersionIds: {'v-number'},
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('This game is no longer available.'), findsOneWidget);
  });

  testWidgets('mid-play poll surfaces kill switch banner', (tester) async {
    await tester.binding.setSurfaceSize(const Size(900, 1400));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    final repo = FakeGameSessionRepository();
    await tester.pumpWidget(
      NanoLocaleScope(
        locale: NanoAppLocale.en,
        copy: const NanoCopy(NanoAppLocale.en),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: GameHostPage(
            game: game,
            sessionRepository: repo,
            playStatusPollInterval: const Duration(milliseconds: 40),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.textContaining('Fixture host'), findsOneWidget);

    repo.forceAbortActive();
    await tester.pump(const Duration(milliseconds: 60));
    await tester.pumpAndSettle();

    expect(find.text('This game was turned off by Nano.'), findsOneWidget);
    expect(find.textContaining('Fixture host'), findsNothing);
  });
}
