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
  StudentPreferencesRepository? preferencesRepository,
  ValueChanged<StudentPreferences>? onPreferences,
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
        preferencesRepository: preferencesRepository,
        preferences: StudentPreferences(userId: principal.userId ?? 'local'),
        onPreferencesChanged: onPreferences,
        onProgressChanged: (_) {},
        onCompleted: (_, track) => onCompleted?.call(track),
      ),
    ),
  );
}

/// Rebuilds the page under a fresh key whenever settings change, the way the
/// app rebuilds its router.
class _RemountingHost extends StatefulWidget {
  const _RemountingHost({
    required this.repository,
    required this.preferencesRepository,
  });

  final OnboardingRepository repository;
  final StudentPreferencesRepository preferencesRepository;

  @override
  State<_RemountingHost> createState() => _RemountingHostState();
}

class _RemountingHostState extends State<_RemountingHost> {
  var _generation = 0;
  StudentPreferences _preferences = const StudentPreferences(userId: 'u1');
  OnboardingProgress _progress = const OnboardingProgress(
    userId: 'u1',
    currentStep: OnboardingStep.preferences,
    selfReportedGradeLevel: 3,
  );

  @override
  Widget build(BuildContext context) {
    return NanoLocaleScope(
      locale: NanoAppLocale.en,
      copy: const NanoCopy(NanoAppLocale.en),
      child: MaterialApp(
        home: OnboardingFlowPage(
          key: ValueKey(_generation),
          repository: widget.repository,
          progress: _progress,
          principal: SessionPrincipal.junior(displayName: 'Ali')
              .copyWith(userId: 'u1', isAuthenticated: true),
          preferencesRepository: widget.preferencesRepository,
          preferences: _preferences,
          onPreferencesChanged: (prefs) => setState(() {
            _preferences = prefs;
            _generation++;
          }),
          onProgressChanged: (progress) => _progress = progress,
          onCompleted: (_, _) {},
        ),
      ),
    );
  }
}

/// Settings repository that answers a frame later, like a network round trip.
class _SlowPreferencesRepository implements StudentPreferencesRepository {
  final _inner = FakeStudentPreferencesRepository();

  @override
  Future<StudentPreferences> load(String userId) => _inner.load(userId);

  @override
  Future<StudentPreferences> save(StudentPreferences preferences) async {
    await Future<void>.delayed(const Duration(milliseconds: 50));
    return _inner.save(preferences);
  }
}

class _FailingOnboardingRepository implements OnboardingRepository {
  @override
  Future<OnboardingProgress> load(String userId) async =>
      OnboardingProgress(userId: userId);

  @override
  Future<OnboardingProgress> save(OnboardingProgress progress) async =>
      throw StateError('offline');
}

void main() {
  testWidgets('school learner walks welcome to ready and completes',
      (tester) async {
    final repo = FakeOnboardingRepository();
    final prefsRepo = FakeStudentPreferencesRepository();
    ExperienceTrack? completedTrack;

    await tester.pumpWidget(
      _host(
        repository: repo,
        preferencesRepository: prefsRepo,
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
    expect(find.text('Name your learning guide'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Tara');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Alpha Academy'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('You are all set'), findsOneWidget);
    expect(find.textContaining('Tara is ready'), findsOneWidget);

    await tester.tap(find.text('Start learning'));
    await tester.pumpAndSettle();

    expect(completedTrack, ExperienceTrack.junior);
    expect(repo.writes.last.isComplete, isTrue);
    expect(repo.writes.last.experienceTrack, ExperienceTrack.junior);
  });

  testWidgets('preferences step rejects a blank companion name',
      (tester) async {
    await tester.pumpWidget(
      _host(
        repository: FakeOnboardingRepository(),
        progress: const OnboardingProgress(
          userId: 'u1',
          currentStep: OnboardingStep.preferences,
        ),
        principal: SessionPrincipal.junior(displayName: 'Ali')
            .copyWith(userId: 'u1', isAuthenticated: true),
        preferencesRepository: FakeStudentPreferencesRepository(),
      ),
    );

    await tester.enterText(find.byType(TextField), '   ');
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    expect(find.text('Enter a name'), findsOneWidget);
    expect(find.textContaining('learning on your own'), findsNothing);
  });

  testWidgets('preferences step applies locale immediately', (tester) async {
    NanoAppLocale? applied;
    await tester.pumpWidget(
      _host(
        repository: FakeOnboardingRepository(),
        progress: const OnboardingProgress(
          userId: 'u1',
          currentStep: OnboardingStep.preferences,
        ),
        principal: SessionPrincipal.junior(displayName: 'Ali')
            .copyWith(userId: 'u1', isAuthenticated: true),
        preferencesRepository: FakeStudentPreferencesRepository(),
        onPreferences: (prefs) => applied = prefs.locale,
      ),
    );

    await tester.tap(find.text('Urdu'));
    await tester.pumpAndSettle();
    expect(applied, NanoAppLocale.ur);
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

  testWidgets('preferences step survives an app rebuild on settings change',
      (tester) async {
    // The real app recreates its router when settings change, which remounts
    // this page. The step must still be saved.
    final repo = FakeOnboardingRepository();
    await tester.pumpWidget(
      _RemountingHost(
        repository: repo,
        preferencesRepository: _SlowPreferencesRepository(),
      ),
    );

    expect(find.text('Name your learning guide'), findsOneWidget);
    await tester.enterText(find.byType(TextField), 'Tara');
    await tester.tap(find.text('Continue'));
    await tester.pump();
    await tester.pumpAndSettle(const Duration(milliseconds: 100));

    expect(repo.writes.last.currentStep, OnboardingStep.context);
    expect(find.text("Couldn't save. Check your connection and try again."),
        findsNothing);
  });

  testWidgets('a failed save explains itself instead of doing nothing',
      (tester) async {
    await tester.pumpWidget(
      _host(
        repository: _FailingOnboardingRepository(),
        progress: const OnboardingProgress(
          userId: 'u1',
          currentStep: OnboardingStep.preferences,
        ),
        principal: SessionPrincipal.junior(displayName: 'Ali')
            .copyWith(userId: 'u1', isAuthenticated: true),
        preferencesRepository: FakeStudentPreferencesRepository(),
      ),
    );

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    expect(
      find.text("Couldn't save. Check your connection and try again."),
      findsOneWidget,
    );
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNotNull,
    );
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
