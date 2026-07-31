import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeOnboardingRepository', () {
    test('starts a new learner at welcome', () async {
      final repo = FakeOnboardingRepository();
      final progress = await repo.load('u1');
      expect(progress.currentStep, OnboardingStep.welcome);
      expect(progress.isComplete, isFalse);
    });

    test('persists each step so an interrupted learner resumes', () async {
      final repo = FakeOnboardingRepository();
      await repo.save(
        const OnboardingProgress(
          userId: 'u1',
          currentStep: OnboardingStep.context,
          selfReportedGradeLevel: 4,
          experienceTrack: ExperienceTrack.junior,
        ),
      );

      final reloaded = await repo.load('u1');
      expect(reloaded.resumeStep, OnboardingStep.context);
      expect(reloaded.selfReportedGradeLevel, 4);
      expect(repo.writes, hasLength(1));
    });

    test('keeps learners separate', () async {
      final repo = FakeOnboardingRepository();
      await repo.save(
        OnboardingProgress(
          userId: 'u1',
          currentStep: OnboardingStep.ready,
          completedAt: DateTime.utc(2026, 7, 31),
        ),
      );
      final other = await repo.load('u2');
      expect(other.isComplete, isFalse);
      expect(other.currentStep, OnboardingStep.welcome);
    });
  });
}
