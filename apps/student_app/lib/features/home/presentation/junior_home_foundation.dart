import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';

/// Junior phone-first home composition (UI_reference/kids/home).
class JuniorHomeFoundation extends StatelessWidget {
  const JuniorHomeFoundation({
    super.key,
    this.studentName = StudentHomeFixtures.studentName,
    this.subjects = StudentHomeFixtures.subjects,
    this.onContinue,
    this.onSubjectTap,
  });

  final String studentName;
  final List<LearningSubject> subjects;
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
          junior: true,
        );
        return NanoMaxContentWidth(
          child: ListView(
            padding: const EdgeInsets.only(bottom: NanoSpacing.xxl),
            children: [
              const SizedBox(height: NanoSpacing.md),
              Row(
                children: [
                  const CompanionSlot(size: 56),
                  const SizedBox(width: NanoSpacing.sm),
                  Expanded(
                    child: Text(
                      copy.greeting(studentName),
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const XpChip(xp: StudentHomeFixtures.xp),
                ],
              ),
              const SizedBox(height: NanoSpacing.lg),
              _ContinueCard(onContinue: onContinue, copy: copy),
              const SizedBox(height: NanoSpacing.lg),
              Text(copy.subjects, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: NanoSpacing.sm,
                  crossAxisSpacing: NanoSpacing.sm,
                  childAspectRatio: 1.05,
                ),
                itemBuilder: (context, index) {
                  final subject = subjects[index];
                  return JuniorActionCard(
                    title: subject.title,
                    subtitle: subject.shortPrompt,
                    backgroundColor: Color(subject.worldColorValue),
                    onTap: onSubjectTap == null
                        ? null
                        : () => onSubjectTap!(subject),
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

class _ContinueCard extends StatelessWidget {
  const _ContinueCard({required this.copy, this.onContinue});

  final NanoCopy copy;
  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    return JuniorActionCard(
      title: StudentHomeFixtures.continueTitle,
      subtitle: copy.continueLearning,
      backgroundColor: NanoColors.worldStories,
      onTap: onContinue,
    );
  }
}
