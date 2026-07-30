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
                      'Hi $studentName',
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                  ),
                  const XpChip(xp: StudentHomeFixtures.xp),
                ],
              ),
              const SizedBox(height: NanoSpacing.lg),
              _ContinueCard(onContinue: onContinue),
              const SizedBox(height: NanoSpacing.lg),
              Text('Subjects', style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: NanoSpacing.sm),
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: subjects.length,
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: columns,
                  mainAxisSpacing: NanoSpacing.listGapJunior,
                  crossAxisSpacing: NanoSpacing.listGapJunior,
                  childAspectRatio: windowSize == NanoWindowSize.phone ? 1.05 : 1.2,
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
  const _ContinueCard({this.onContinue});

  final VoidCallback? onContinue;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    return Material(
      color: NanoColors.brandPrimary,
      borderRadius: BorderRadius.circular(nano.cardRadius),
      child: InkWell(
        onTap: onContinue,
        borderRadius: BorderRadius.circular(nano.cardRadius),
        child: Padding(
          padding: EdgeInsets.all(nano.cardPadding),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Continue Learning',
                      style: Theme.of(context).textTheme.labelLarge,
                    ),
                    const SizedBox(height: NanoSpacing.xxs),
                    Text(
                      StudentHomeFixtures.continueTitle,
                      style: Theme.of(context).textTheme.headlineMedium,
                    ),
                    const SizedBox(height: NanoSpacing.sm),
                    FilledButton.tonal(
                      onPressed: onContinue,
                      child: const Text('Start'),
                    ),
                  ],
                ),
              ),
              const CompanionSlot(size: 88, semanticLabel: 'Nori'),
            ],
          ),
        ),
      ),
    );
  }
}
