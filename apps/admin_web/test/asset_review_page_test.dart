import 'package:admin_web/features/moderation/presentation/asset_review_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

Future<void> _pump(
  WidgetTester tester, {
  required AssetReviewRepository repository,
  NanoAppLocale locale = NanoAppLocale.en,
}) async {
  await tester.binding.setSurfaceSize(const Size(1400, 1200));
  addTearDown(() => tester.binding.setSurfaceSize(null));
  await tester.pumpWidget(
    NanoLocaleScope(
      locale: locale,
      copy: NanoCopy(locale),
      child: MaterialApp(home: AssetReviewPage(repository: repository)),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('the queue opens on what has not been decided', (tester) async {
    await _pump(tester, repository: FakeAssetReviewRepository());

    expect(find.text('Media review'), findsOneWidget);
    expect(find.text('guide_greeting_staticArt'), findsWidgets);
    expect(find.text('Approve'), findsOneWidget);
    expect(find.text('Reject'), findsOneWidget);
  });

  testWidgets('a reviewer sees the prompt and provider behind an asset',
      (tester) async {
    await _pump(tester, repository: FakeAssetReviewRepository());

    await tester.tap(find.text('guide_greeting_staticArt').last);
    await tester.pumpAndSettle();

    // Publication approves a prompt as much as a picture, because the same
    // prompt is reused for every later ask that matches it. It is selectable so
    // a reviewer can copy it into a regeneration.
    expect(find.text('Prompt'), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is SelectableText &&
            (widget.data ?? '').contains('A small round friendly companion'),
      ),
      findsOneWidget,
    );
    expect(find.textContaining('pollinations_image'), findsOneWidget);
  });

  testWidgets('approving publishes and reports what changed', (tester) async {
    final repository = FakeAssetReviewRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.text('Approve'));
    await tester.pumpAndSettle();

    final published = await repository.queue(
      moderation: GeneratedAssetModeration.approved,
    );
    expect(published, hasLength(1));
    expect(find.textContaining('Decided 1'), findsOneWidget);
  });

  testWidgets('rejecting without a reason is refused and says why',
      (tester) async {
    final repository = FakeAssetReviewRepository();
    await _pump(tester, repository: repository);

    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    expect(find.textContaining('needs a reason'), findsOneWidget);
    final rejected = await repository.queue(
      moderation: GeneratedAssetModeration.rejected,
    );
    expect(rejected, isEmpty);
  });

  testWidgets('rejecting with a reason records it', (tester) async {
    final repository = FakeAssetReviewRepository();
    await _pump(tester, repository: repository);

    await tester.enterText(find.byType(TextField), 'Six fingers.');
    await tester.tap(find.text('Reject'));
    await tester.pumpAndSettle();

    final rejected = await repository.queue(
      moderation: GeneratedAssetModeration.rejected,
    );
    expect(rejected, hasLength(1));
    final history = await repository.history(rejected.single.id);
    expect(history.single.note, 'Six fingers.');
  });

  testWidgets('a job with no file cannot be approved and says so',
      (tester) async {
    final repository = FakeAssetReviewRepository();
    await _pump(tester, repository: repository);

    // The stuck voice job is listed so the slot is visible, but Approve is
    // disabled rather than hidden, with the reason spelled out.
    await tester.tap(find.text('guide_greeting_voice'));
    await tester.pumpAndSettle();

    expect(find.text('Only a ready asset can be approved'), findsOneWidget);
    final approve = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, 'Approve'),
    );
    expect(approve.onPressed, isNull);
  });

  testWidgets('a refused queue shows the server sentence, not a blank list',
      (tester) async {
    // What a school admin who reached this screen would see.
    await _pump(tester, repository: FakeAssetReviewRepository(alwaysFail: true));

    expect(find.textContaining('unavailable'), findsWidgets);
  });

  testWidgets('an empty queue reads as finished work, not as an error',
      (tester) async {
    await _pump(tester, repository: FakeAssetReviewRepository(seed: const []));

    expect(find.text('Nothing to review'), findsOneWidget);
  });

  testWidgets('the review surface is translated', (tester) async {
    await _pump(
      tester,
      repository: FakeAssetReviewRepository(),
      locale: NanoAppLocale.ur,
    );

    expect(find.text('Approve'), findsNothing);
    expect(find.text('منظور کریں'), findsOneWidget);
  });
}
