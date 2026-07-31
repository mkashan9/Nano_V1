import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';

/// Senior denser home composition (UI_reference/four_12/home).
class SeniorHomeFoundation extends StatelessWidget {
  const SeniorHomeFoundation({
    super.key,
    this.studentName = StudentHomeFixtures.studentName,
    this.subjects = StudentHomeFixtures.subjects,
    this.missions = StudentHomeFixtures.missions,
    this.onContinue,
    this.onSubjectTap,
  });

  final String studentName;
  final List<LearningSubject> subjects;
  final List<HomePlanItem> missions;
  final VoidCallback? onContinue;
  final ValueChanged<LearningSubject>? onSubjectTap;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    return NanoResponsiveBuilder(
      builder: (context, windowSize, _) {
        final columns = NanoResponsive.subjectColumnsFor(
          size: windowSize,
          junior: false,
        );
        return NanoMaxContentWidth(
          maxWidth: windowSize == NanoWindowSize.desktop ? 960 : 720,
          child: ListView(
            padding: const EdgeInsets.only(bottom: NanoSpacing.xxl),
            children: [
              const SizedBox(height: NanoSpacing.md),
              Row(
                children: [
                  const CompanionSlot(size: 48),
                  const SizedBox(width: NanoSpacing.sm),
                  Expanded(
                    child: Text(
                      copy.buildingFuture,
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                  ),
                  const XpChip(xp: StudentHomeFixtures.xp),
                ],
              ),
              const SizedBox(height: NanoSpacing.lg),
              SeniorProgressCard(
                title: 'Space Explorer Game',
                tag: 'Continue Building',
                progress: StudentHomeFixtures.continueProgress,
                meta: 'Resume your current project',
                onTap: onContinue,
              ),
              const SizedBox(height: NanoSpacing.lg),
              Text(copy.todaysMission, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              ...missions.map(
                (m) => Padding(
                  padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                  child: TeacherTaskCard(
                    title: m.title,
                    subtitle: '${m.subtitle} · +${m.xpReward} XP',
                    onTap: () {},
                  ),
                ),
              ),
              const SizedBox(height: NanoSpacing.md),
              Text('Continue Learning', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              if (columns == 1)
                ...subjects.map(
                  (s) => Padding(
                    padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                    child: SeniorProgressCard(
                      title: s.title,
                      tag: s.tag,
                      progress: s.progress,
                      meta: '${s.estimatedMinutes} min',
                      onTap: onSubjectTap == null ? null : () => onSubjectTap!(s),
                    ),
                  ),
                )
              else
                GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: subjects.length,
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: NanoSpacing.listGapSenior,
                    crossAxisSpacing: NanoSpacing.listGapSenior,
                    childAspectRatio: 1.6,
                  ),
                  itemBuilder: (context, index) {
                    final s = subjects[index];
                    return SeniorProgressCard(
                      title: s.title,
                      tag: s.tag,
                      progress: s.progress,
                      meta: '${s.estimatedMinutes} min',
                      onTap: onSubjectTap == null ? null : () => onSubjectTap!(s),
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }
}
