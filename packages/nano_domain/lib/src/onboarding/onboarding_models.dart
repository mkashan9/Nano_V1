import '../navigation/app_role.dart';

/// Ordered first-run steps. Persisted as text, so the names are contract.
enum OnboardingStep { welcome, experience, preferences, context, ready }

extension OnboardingStepX on OnboardingStep {
  String get wireName => name;

  static OnboardingStep fromWire(String? raw) => switch (raw) {
        'experience' => OnboardingStep.experience,
        'preferences' => OnboardingStep.preferences,
        'context' => OnboardingStep.context,
        'ready' => OnboardingStep.ready,
        _ => OnboardingStep.welcome,
      };

  bool get isLast => this == OnboardingStep.ready;

  OnboardingStep get next => isLast
      ? this
      : OnboardingStep.values[OnboardingStep.values.indexOf(this) + 1];

  OnboardingStep get previous => this == OnboardingStep.welcome
      ? this
      : OnboardingStep.values[OnboardingStep.values.indexOf(this) - 1];
}

/// Junior or senior presentation, independent of school linkage.
enum ExperienceTrack { junior, senior }

extension ExperienceTrackX on ExperienceTrack {
  String get wireName => name;

  static ExperienceTrack? fromWire(String? raw) => switch (raw) {
        'junior' => ExperienceTrack.junior,
        'senior' => ExperienceTrack.senior,
        _ => null,
      };
}

/// Derives the experience track. Grade policy wins; the learner's self-report
/// is only a fallback until a school record exists (SCH-04).
abstract final class ExperiencePolicy {
  static const juniorMaxGrade = 5;

  static ExperienceTrack fromGradeLevel(int gradeLevel) =>
      gradeLevel <= juniorMaxGrade
          ? ExperienceTrack.junior
          : ExperienceTrack.senior;

  static ExperienceTrack resolve({
    int? verifiedGradeLevel,
    int? selfReportedGradeLevel,
    ExperienceTrack? authorizedOverride,
  }) {
    if (authorizedOverride != null) return authorizedOverride;
    final grade = verifiedGradeLevel ?? selfReportedGradeLevel;
    return grade == null
        ? ExperienceTrack.senior
        : fromGradeLevel(grade);
  }

  /// Independent learners never reach Flex, whatever their track.
  static AppRole roleFor({
    required ExperienceTrack track,
    required bool independent,
  }) {
    if (independent) return AppRole.independentStudent;
    return track == ExperienceTrack.junior
        ? AppRole.juniorStudent
        : AppRole.seniorStudent;
  }
}

/// Server-backed first-run progress for one learner.
class OnboardingProgress {
  const OnboardingProgress({
    required this.userId,
    this.currentStep = OnboardingStep.welcome,
    this.selfReportedGradeLevel,
    this.experienceTrack,
    this.completedAt,
  });

  final String userId;
  final OnboardingStep currentStep;
  final int? selfReportedGradeLevel;
  final ExperienceTrack? experienceTrack;
  final DateTime? completedAt;

  bool get isComplete => completedAt != null;

  /// Where an interrupted learner should land on next launch.
  OnboardingStep get resumeStep =>
      isComplete ? OnboardingStep.ready : currentStep;

  OnboardingProgress copyWith({
    OnboardingStep? currentStep,
    int? selfReportedGradeLevel,
    ExperienceTrack? experienceTrack,
    DateTime? completedAt,
  }) {
    return OnboardingProgress(
      userId: userId,
      currentStep: currentStep ?? this.currentStep,
      selfReportedGradeLevel:
          selfReportedGradeLevel ?? this.selfReportedGradeLevel,
      experienceTrack: experienceTrack ?? this.experienceTrack,
      completedAt: completedAt ?? this.completedAt,
    );
  }

  factory OnboardingProgress.fromRow(Map<String, dynamic> row) {
    final completedRaw = row['completed_at'] as String?;
    return OnboardingProgress(
      userId: row['user_id'] as String,
      currentStep: OnboardingStepX.fromWire(row['current_step'] as String?),
      selfReportedGradeLevel:
          (row['self_reported_grade_level'] as num?)?.toInt(),
      experienceTrack:
          ExperienceTrackX.fromWire(row['experience_track'] as String?),
      completedAt:
          completedRaw == null ? null : DateTime.tryParse(completedRaw),
    );
  }

  Map<String, dynamic> toRow() => {
        'user_id': userId,
        'current_step': currentStep.wireName,
        'self_reported_grade_level': selfReportedGradeLevel,
        'experience_track': experienceTrack?.wireName,
        'completed_at': completedAt?.toUtc().toIso8601String(),
      };
}
