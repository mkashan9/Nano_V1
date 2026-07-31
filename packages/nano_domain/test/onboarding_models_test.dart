import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('OnboardingStep', () {
    test('walks forward and back without leaving the range', () {
      expect(OnboardingStep.welcome.next, OnboardingStep.experience);
      expect(OnboardingStep.ready.next, OnboardingStep.ready);
      expect(OnboardingStep.welcome.previous, OnboardingStep.welcome);
      expect(OnboardingStep.context.previous, OnboardingStep.experience);
    });

    test('round-trips through its wire name', () {
      for (final step in OnboardingStep.values) {
        expect(OnboardingStepX.fromWire(step.wireName), step);
      }
      expect(OnboardingStepX.fromWire('nonsense'), OnboardingStep.welcome);
      expect(OnboardingStepX.fromWire(null), OnboardingStep.welcome);
    });
  });

  group('ExperiencePolicy', () {
    test('grade 5 and below is junior', () {
      expect(ExperiencePolicy.fromGradeLevel(1), ExperienceTrack.junior);
      expect(ExperiencePolicy.fromGradeLevel(5), ExperienceTrack.junior);
      expect(ExperiencePolicy.fromGradeLevel(6), ExperienceTrack.senior);
    });

    test('verified grade beats self-report, override beats both', () {
      expect(
        ExperiencePolicy.resolve(
          verifiedGradeLevel: 3,
          selfReportedGradeLevel: 9,
        ),
        ExperienceTrack.junior,
      );
      expect(
        ExperiencePolicy.resolve(
          verifiedGradeLevel: 3,
          authorizedOverride: ExperienceTrack.senior,
        ),
        ExperienceTrack.senior,
      );
    });

    test('independent learners never take a school role', () {
      expect(
        ExperiencePolicy.roleFor(
          track: ExperienceTrack.junior,
          independent: true,
        ),
        AppRole.independentStudent,
      );
      expect(
        ExperiencePolicy.roleFor(
          track: ExperienceTrack.junior,
          independent: false,
        ),
        AppRole.juniorStudent,
      );
    });
  });

  group('OnboardingProgress', () {
    test('resumes at the saved step until completion', () {
      const progress = OnboardingProgress(
        userId: 'u1',
        currentStep: OnboardingStep.context,
      );
      expect(progress.resumeStep, OnboardingStep.context);
      expect(progress.isComplete, isFalse);

      final done = progress.copyWith(completedAt: DateTime.utc(2026, 7, 31));
      expect(done.isComplete, isTrue);
      expect(done.resumeStep, OnboardingStep.ready);
    });

    test('round-trips through a database row', () {
      final row = {
        'user_id': 'u1',
        'current_step': 'experience',
        'self_reported_grade_level': 7,
        'experience_track': 'senior',
        'completed_at': null,
      };
      final progress = OnboardingProgress.fromRow(row);
      expect(progress.currentStep, OnboardingStep.experience);
      expect(progress.selfReportedGradeLevel, 7);
      expect(progress.experienceTrack, ExperienceTrack.senior);
      expect(progress.toRow()['current_step'], 'experience');
    });
  });
}
