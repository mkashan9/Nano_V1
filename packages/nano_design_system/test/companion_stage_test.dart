import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  final t0 = DateTime.utc(2026, 8, 1, 9);

  CompanionReaction? reactionFor(
    CompanionEvent event, {
    bool junior = true,
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    String companionName = 'Nori',
  }) {
    return CompanionRuntime.forExperience(
      junior: junior,
      preferences: preferences,
      companionName: companionName,
    ).notify(event, now: t0).reaction;
  }

  Future<void> pumpStage(
    WidgetTester tester,
    CompanionReaction? reaction, {
    NanoAppLocale locale = NanoAppLocale.en,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionStage(reaction: reaction, locale: locale),
        ),
      ),
    );
  }

  testWidgets('shows the caption for the reaction', (tester) async {
    await pumpStage(tester, reactionFor(CompanionEvent.appOpen));
    expect(find.textContaining('help you learn, play'), findsOneWidget);
    expect(find.byType(CompanionSlot), findsOneWidget);
  });

  testWidgets('renders nothing when there is no reaction', (tester) async {
    await pumpStage(tester, reactionFor(CompanionEvent.home, junior: false));
    expect(find.byType(CompanionSlot), findsNothing);
    expect(find.byType(Text), findsNothing);
  });

  testWidgets('keeps the art but drops the caption when captions are off', (
    tester,
  ) async {
    await pumpStage(
      tester,
      reactionFor(
        CompanionEvent.appOpen,
        preferences: const AccessibilityPreferences(captionsEnabled: false),
      ),
    );
    expect(find.byType(CompanionSlot), findsOneWidget);
    expect(find.textContaining('Nori'), findsNothing);
  });

  testWidgets('uses the learner companion name in the semantic label', (
    tester,
  ) async {
    await pumpStage(
      tester,
      reactionFor(CompanionEvent.appOpen, companionName: 'Bao'),
    );
    expect(find.bySemanticsLabel('Bao'), findsOneWidget);
    // The caption and the mode badge both name the companion.
    expect(find.textContaining('Bao'), findsWidgets);
  });

  testWidgets('shows the Urdu caption for an Urdu locale', (tester) async {
    await pumpStage(
      tester,
      reactionFor(CompanionEvent.resultNeedsReview),
      locale: NanoAppLocale.ur,
    );
    expect(find.textContaining('دوبارہ'), findsOneWidget);
  });

  testWidgets('senior result guidance is smaller than junior', (tester) async {
    await pumpStage(tester, reactionFor(CompanionEvent.resultPassed));
    final juniorSize = tester.getSize(find.byType(CompanionSlot));
    await pumpStage(
      tester,
      reactionFor(CompanionEvent.resultPassed, junior: false),
    );
    final seniorSize = tester.getSize(find.byType(CompanionSlot));
    expect(seniorSize.width, lessThan(juniorSize.width));
  });

  testWidgets('dismiss action is offered only when a handler is given', (
    tester,
  ) async {
    var dismissed = false;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: CompanionStage(
            reaction: reactionFor(CompanionEvent.appOpen),
            onDismiss: () => dismissed = true,
          ),
        ),
      ),
    );
    await tester.tap(find.byIcon(Icons.close));
    expect(dismissed, isTrue);
  });
}
