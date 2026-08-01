import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/main.dart';

/// The experience a learner sees follows the track onboarding recorded.
///
/// Two defects met here. Sign-in reads `profiles`, and the track lives in
/// `student_onboarding`, so the auth bootstrap could never know it — and the
/// app loaded the track on every sign-in and then dropped it, applying it only
/// in the session where onboarding happened to finish. On top of that, an
/// independent learner is always [AppRole.independentStudent] whatever their
/// age, so the role alone could not say "independent and six years old".
/// Together those handed a returning Junior learner the Senior experience, and
/// Senior treats home as a quiet moment, so the companion never appeared.
void main() {
  const config = EnvironmentConfig(
    environment: NanoEnvironment.development,
    supabaseUrl: '',
    supabaseAnonKey: '',
    featureFlags: {'diagnostics': true},
  );

  group('presentation on the principal', () {
    test('a known track beats the role', () {
      final child = SessionPrincipal.independent()
          .copyWith(experienceTrack: ExperienceTrack.junior);
      expect(child.role, AppRole.independentStudent);
      expect(child.usesJuniorPresentation, isTrue);

      final teen = SessionPrincipal.independent()
          .copyWith(experienceTrack: ExperienceTrack.senior);
      expect(teen.usesJuniorPresentation, isFalse);
    });

    test('no track falls back to the role, exactly as before', () {
      expect(SessionPrincipal.junior().usesJuniorPresentation, isTrue);
      expect(SessionPrincipal.seniorSchool().usesJuniorPresentation, isFalse);
      expect(SessionPrincipal.independent().usesJuniorPresentation, isFalse);
    });

    test('a school student on the senior track stops being Junior', () {
      // The auth bootstrap has one branch for every school student and it
      // guesses Junior. The loaded track has to be able to overrule it.
      final guessed = SessionPrincipal.junior(displayName: 'Bina');
      expect(guessed.usesJuniorPresentation, isTrue);
      expect(
        guessed.copyWith(experienceTrack: ExperienceTrack.senior)
            .usesJuniorPresentation,
        isFalse,
      );
    });
  });

  group('a returning learner', () {
    /// Comes back the way the real app does: a session restored from the
    /// account kind alone, with the track arriving afterwards from the
    /// repository. Nothing here tells the app which experience to use.
    Future<void> signIn(
      WidgetTester tester, {
      required ExperienceTrack track,
      required int grade,
    }) async {
      await tester.binding.setSurfaceSize(const Size(1000, 1600));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final auth = FakeAuthRepository(
        bootstrapBuilder: () => AuthBootstrap(
          principal: SessionPrincipal.independent(displayName: 'Jan').copyWith(
            userId: 'learner-1',
            isAuthenticated: true,
          ),
          schoolStatus: SchoolStatus.active,
          profileStatus: MembershipStatus.active,
          membershipStatus: MembershipStatus.active,
        ),
      );
      await auth.signInWithPassword(
        email: AuthFixtures.aliEmail,
        password: AuthFixtures.aliPassword,
      );
      await tester.pumpWidget(
        NanoStudentApp(
          config: config,
          authRepository: auth,
          requireAuth: true,
          onboardingRepository: FakeOnboardingRepository(
            seed: OnboardingProgress(
              userId: 'learner-1',
              currentStep: OnboardingStep.ready,
              selfReportedGradeLevel: grade,
              experienceTrack: track,
              completedAt: DateTime.utc(2026, 7, 1),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
    }

    // Junior calls the profile destination "Me" and Senior calls it "Profile",
    // so the nav bar is the cheapest honest proof of which experience rendered.
    testWidgets('an independent Junior gets the Junior experience',
        (tester) async {
      await signIn(tester, track: ExperienceTrack.junior, grade: 1);
      expect(find.text('Me'), findsWidgets);
      expect(find.text('Profile'), findsNothing);
    });

    testWidgets('an independent Senior gets the Senior experience',
        (tester) async {
      await signIn(tester, track: ExperienceTrack.senior, grade: 6);
      expect(find.text('Profile'), findsWidgets);
      expect(find.text('Me'), findsNothing);
    });
  });
}
