import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/onboarding/presentation/onboarding_flow_page.dart';

Widget _host({
  required OnboardingRepository repository,
  required OnboardingProgress progress,
  required SessionPrincipal principal,
  ValueChanged<ExperienceTrack>? onCompleted,
  String? schoolName,
}) {
  return NanoLocaleScope(
    locale: NanoAppLocale.en,
    copy: const NanoCopy(NanoAppLocale.en),
    child: MaterialApp(
      home: OnboardingFlowPage(
        repository: repository,
        progress: progress,
        principal: principal,
        schoolName: schoolName,
        onProgressChanged: (_) {},
        onCompleted: (_, track) => onCompleted?.call(track),
      ),
    ),
  );
}

void main() {
  testWidgets('school learner walks welcome to ready and completes',
      (tester) async {
    final repo = FakeOnboardingRepository();
    ExperienceTrack? completedTrack;

    await tester.pumpWidget(
      _host(
        repository: repo,
        progress: const OnboardingProgress(userId: 'u1'),
        principal: SessionPrincipal.junior(displayName: 'Ali')
            .copyWith(userId: 'u1', schoolId: 's1', isAuthenticated: true),
        schoolName: 'Alpha Academy',
        onCompleted: (track) => completedTrack = track,
      ),
    );

    expect(find.text('Welcome to Nano'), findsOneWidget);
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(find.text('Which grade are you in?'), findsOneWidget);
    await tester.tap(find.widgetWithText(ChoiceChip, '3'));
    await tester.pumpAndSettle();
    expect(find.text('Junior'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Alpha Academy'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('You are all set'), findsOneWidget);

    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    expect(completedTrack, ExperienceTrack.junior);
    expect(repo.writes.last.isComplete, isTrue);
    expect(repo.writes.last.experienceTrack, ExperienceTrack.junior);
  });

  testWidgets('interrupted learner resumes at the saved step', (tester) async {
    await tester.pumpWidget(
      _host(
        repository: FakeOnboardingRepository(),
        progress: const OnboardingProgress(
          userId: 'u1',
          currentStep: OnboardingStep.context,
          selfReportedGradeLevel: 8,
          experienceTrack: ExperienceTrack.senior,
        ),
        principal: SessionPrincipal.independent(displayName: 'Sana')
            .copyWith(userId: 'u1', isAuthenticated: true),
      ),
    );

    expect(find.text('We saved your place'), findsOneWidget);
    expect(find.text('Welcome to Nano'), findsNothing);
    expect(find.textContaining('learning on your own'), findsOneWidget);
  });

  testWidgets('independent onboarding never promises school features',
      (tester) async {
    await tester.pumpWidget(
      _host(
        repository: FakeOnboardingRepository(),
        progress: const OnboardingProgress(
          userId: 'u1',
          currentStep: OnboardingStep.context,
        ),
        principal: SessionPrincipal.independent(displayName: 'Sana')
            .copyWith(userId: 'u1', isAuthenticated: true),
      ),
    );

    expect(find.textContaining('Flex'), findsNothing);
    expect(find.textContaining('Attendance'), findsNothing);
  });

  testWidgets('grade step blocks continue until a grade is chosen',
      (tester) async {
    await tester.pumpWidget(
      _host(
        repository: FakeOnboardingRepository(),
        progress: const OnboardingProgress(
          userId: 'u1',
          currentStep: OnboardingStep.experience,
        ),
        principal: SessionPrincipal.junior(displayName: 'Ali')
            .copyWith(userId: 'u1', isAuthenticated: true),
      ),
    );

    final button = tester.widget<FilledButton>(find.byType(FilledButton));
    expect(button.onPressed, isNull);

    await tester.tap(find.widgetWithText(ChoiceChip, '9'));
    await tester.pumpAndSettle();
    expect(find.text('Senior'), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
  });
}
