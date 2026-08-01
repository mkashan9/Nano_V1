import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/quiz/presentation/junior_quiz_page.dart';
import 'package:student_app/features/quiz/presentation/senior_quiz_page.dart';

const _counting = 'tv-counting-1';

var _now = DateTime.utc(2026, 8, 2, 10);

CompanionController _controller({bool junior = true}) {
  return CompanionController(junior: junior, clock: () => _now);
}

Future<void> _pump(
  WidgetTester tester,
  Widget page, {
  required CompanionController companion,
  AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
}) async {
  await tester.binding.setSurfaceSize(const Size(900, 2000));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: NanoCopy(NanoAppLocale.en),
      child: NanoAccessibilityScope(
        preferences: preferences,
        feedback: NanoFeedback(preferences: preferences),
        child: NanoCompanionScope(
          controller: companion,
          child: MaterialApp(home: page),
        ),
      ),
    ),
  );
  await tester.pumpAndSettle();
}

Widget _junior() => JuniorQuizPage(
      topicVersionId: _counting,
      repository: FakeLearnerQuizRepository(),
      attemptRepository: FakeQuizAttemptRepository(),
    );

Widget _senior() => SeniorQuizPage(
      topicVersionId: _counting,
      repository: FakeLearnerQuizRepository(),
      attemptRepository: FakeQuizAttemptRepository(),
    );

Future<void> _finishJunior(
  WidgetTester tester, {
  bool correctly = true,
}) async {
  await tester.tap(find.text(correctly ? 'Five' : 'Three'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Next'));
  await tester.pumpAndSettle();
  await tester.tap(find.text(correctly ? '5' : '4'));
  await tester.pumpAndSettle();
  await tester.tap(find.text('Finish'));
  await tester.pumpAndSettle();
}

/// Which pose Nori is wearing (MED-09).
Set<String> _poses(WidgetTester tester) => tester
    .widgetList<Image>(find.byType(Image))
    .map((image) => image.image)
    .whereType<AssetImage>()
    .map((provider) => provider.assetName)
    .toSet();

void main() {
  setUp(() => _now = DateTime.utc(2026, 8, 2, 10));

  testWidgets('a passed attempt is celebrated', (tester) async {
    final companion = _controller();
    addTearDown(companion.dispose);
    await _pump(tester, _junior(), companion: companion);
    await _finishJunior(tester);

    expect(find.byType(CompanionSurfaceStage), findsWidgets);
    expect(
      _poses(tester),
      contains(NoriPosePack.assetFor(CompanionMood.celebration)),
    );
    expect(find.textContaining('Nicely done!'), findsOneWidget);
    expect(companion.reaction?.mood, CompanionMood.celebration);
  });

  testWidgets('a failed attempt is a gentle retry, not a scolding',
      (tester) async {
    final companion = _controller();
    addTearDown(companion.dispose);
    await _pump(tester, _junior(), companion: companion);
    await _finishJunior(tester, correctly: false);

    expect(
      _poses(tester),
      contains(NoriPosePack.assetFor(CompanionMood.gentleRetry)),
    );
    expect(companion.reaction?.mood, CompanionMood.gentleRetry);
  });

  testWidgets('senior quiz mounts the session companion on questions',
      (tester) async {
    final companion = _controller(junior: false);
    addTearDown(companion.dispose);
    await _pump(tester, _senior(), companion: companion);

    expect(find.byType(CompanionSurfaceStage), findsOneWidget);
    expect(companion.surface, CompanionSurface.quiz);
  });
}
