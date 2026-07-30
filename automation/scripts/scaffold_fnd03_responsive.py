"""Scaffold FND-03 responsive Junior/Senior foundations."""
from __future__ import annotations

from pathlib import Path

ROOT = Path(r"d:\nano")


def w(path: str, content: str) -> None:
    p = ROOT / path
    p.parent.mkdir(parents=True, exist_ok=True)
    p.write_text(content.strip() + "\n", encoding="utf-8")


def main() -> None:
    # Design system responsive helpers
    w(
        "packages/nano_design_system/lib/src/responsive/nano_responsive.dart",
        r"""
import 'package:flutter/material.dart';
import '../tokens/nano_breakpoints.dart';

enum NanoWindowSize { phone, tablet, desktop }

class NanoResponsive {
  static NanoWindowSize windowSizeFor(double width) {
    if (width < NanoBreakpoints.tablet) return NanoWindowSize.phone;
    if (width < NanoBreakpoints.narrowWeb) return NanoWindowSize.tablet;
    return NanoWindowSize.desktop;
  }

  static int subjectColumnsFor({
    required NanoWindowSize size,
    required bool junior,
  }) {
    if (junior) {
      return switch (size) {
        NanoWindowSize.phone => 2,
        NanoWindowSize.tablet => 3,
        NanoWindowSize.desktop => 4,
      };
    }
    return switch (size) {
      NanoWindowSize.phone => 1,
      NanoWindowSize.tablet => 2,
      NanoWindowSize.desktop => 2,
    };
  }
}

typedef NanoResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  NanoWindowSize windowSize,
  BoxConstraints constraints,
);

class NanoResponsiveBuilder extends StatelessWidget {
  const NanoResponsiveBuilder({super.key, required this.builder});

  final NanoResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = NanoResponsive.windowSizeFor(constraints.maxWidth);
        return builder(context, size, constraints);
      },
    );
  }
}

/// Constrains content for large screens while keeping phone-first layouts.
class NanoMaxContentWidth extends StatelessWidget {
  const NanoMaxContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
""",
    )

    # Export update - append to barrel via rewrite of full exports later in script
    barrel = (ROOT / "packages/nano_design_system/lib/nano_design_system.dart").read_text(
        encoding="utf-8"
    )
    if "nano_responsive.dart" not in barrel:
        barrel = barrel.rstrip() + "\nexport 'src/responsive/nano_responsive.dart';\n"
        (ROOT / "packages/nano_design_system/lib/nano_design_system.dart").write_text(
            barrel, encoding="utf-8"
        )

    # Domain fixtures for shared learning subjects
    w(
        "packages/nano_domain/lib/src/learning/learning_subject.dart",
        r"""
/// Shared domain record rendered differently by Junior and Senior shells.
class LearningSubject {
  const LearningSubject({
    required this.id,
    required this.title,
    required this.progress,
    required this.worldColorValue,
    this.tag,
    this.estimatedMinutes,
    this.shortPrompt,
  });

  final String id;
  final String title;
  final double progress;
  final int worldColorValue;
  final String? tag;
  final int? estimatedMinutes;
  final String? shortPrompt;
}
""",
    )
    w(
        "packages/nano_domain/lib/src/learning/home_plan_item.dart",
        r"""
class HomePlanItem {
  const HomePlanItem({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.xpReward,
  });

  final String id;
  final String title;
  final String subtitle;
  final int xpReward;
}
""",
    )
    domainBarrel = (ROOT / "packages/nano_domain/lib/src/nano_domain.dart").read_text(
        encoding="utf-8"
    )
    if "learning_subject.dart" not in domainBarrel:
        domainBarrel = (
            domainBarrel.rstrip()
            + "\nexport 'learning/learning_subject.dart';\n"
            + "export 'learning/home_plan_item.dart';\n"
        )
        (ROOT / "packages/nano_domain/lib/src/nano_domain.dart").write_text(
            domainBarrel, encoding="utf-8"
        )

    w(
        "packages/nano_testing/lib/src/fixtures/student_home_fixtures.dart",
        r"""
import 'package:nano_domain/nano_domain.dart';

/// Deterministic fixtures shared by Junior and Senior presentations.
abstract final class StudentHomeFixtures {
  static const studentName = 'Ali';
  static const xp = 560;
  static const streak = 7;

  static const continueTitle = 'Animals Adventure';
  static const continueProgress = 0.42;

  static const subjects = <LearningSubject>[
    LearningSubject(
      id: 'math',
      title: 'Math',
      progress: 0.55,
      worldColorValue: 0xFF2F7BFF,
      tag: 'Math',
      estimatedMinutes: 25,
      shortPrompt: 'Play numbers',
    ),
    LearningSubject(
      id: 'english',
      title: 'English',
      progress: 0.30,
      worldColorValue: 0xFF2FBF71,
      tag: 'English',
      estimatedMinutes: 30,
      shortPrompt: 'ABC time',
    ),
    LearningSubject(
      id: 'science',
      title: 'Science',
      progress: 0.65,
      worldColorValue: 0xFFFF8A3D,
      tag: 'Science',
      estimatedMinutes: 45,
      shortPrompt: 'Mix & learn',
    ),
    LearningSubject(
      id: 'stories',
      title: 'Stories',
      progress: 0.20,
      worldColorValue: 0xFFFF4F9A,
      tag: 'Stories',
      estimatedMinutes: 20,
      shortPrompt: 'Read along',
    ),
  ];

  static const missions = <HomePlanItem>[
    HomePlanItem(
      id: 'm1',
      title: 'Complete a lesson',
      subtitle: 'Learn',
      xpReward: 40,
    ),
    HomePlanItem(
      id: 'm2',
      title: 'Play one game',
      subtitle: 'Games',
      xpReward: 30,
    ),
    HomePlanItem(
      id: 'm3',
      title: 'Practice quiz',
      subtitle: 'Quiz',
      xpReward: 50,
    ),
  ];
}
""",
    )
    testingSrc = ROOT / "packages/nano_testing/lib/src/nano_testing.dart"
    t = testingSrc.read_text(encoding="utf-8")
    if "student_home_fixtures" not in t:
        testingSrc.write_text(
            t.rstrip()
            + "\nexport 'fixtures/student_home_fixtures.dart';\n",
            encoding="utf-8",
        )
    testingBarrel = ROOT / "packages/nano_testing/lib/nano_testing.dart"
    tb = testingBarrel.read_text(encoding="utf-8")
    if "fixtures" not in tb:
        # already exports src
        pass

    # Student app foundations
    w(
        "apps/student_app/lib/features/home/presentation/junior_home_foundation.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_testing/nano_testing.dart';

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
""",
    )

    w(
        "apps/student_app/lib/features/home/presentation/senior_home_foundation.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_testing/nano_testing.dart';

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
                      "I'm building my future.",
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
              Text("Today's Mission", style: Theme.of(context).textTheme.titleLarge),
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
""",
    )

    w(
        "apps/student_app/lib/features/home/presentation/responsive_preview_page.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'junior_home_foundation.dart';
import 'senior_home_foundation.dart';

/// Development preview for phone / tablet / web widths.
class ResponsivePreviewPage extends StatefulWidget {
  const ResponsivePreviewPage({super.key});

  @override
  State<ResponsivePreviewPage> createState() => _ResponsivePreviewPageState();
}

class _ResponsivePreviewPageState extends State<ResponsivePreviewPage> {
  bool senior = false;
  double previewWidth = 390;

  @override
  Widget build(BuildContext context) {
    final theme = senior ? NanoTheme.senior() : NanoTheme.junior();
    return Theme(
      data: theme,
      child: NanoScaffold(
        padBody: false,
        appBar: AppBar(
          title: const Text('Responsive preview'),
          actions: [
            Text(senior ? 'Senior' : 'Junior'),
            Switch(value: senior, onChanged: (v) => setState(() => senior = v)),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(NanoSpacing.md),
              child: Wrap(
                spacing: NanoSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Phone'),
                    selected: previewWidth == 390,
                    onSelected: (_) => setState(() => previewWidth = 390),
                  ),
                  ChoiceChip(
                    label: const Text('Tablet'),
                    selected: previewWidth == 800,
                    onSelected: (_) => setState(() => previewWidth = 800),
                  ),
                  ChoiceChip(
                    label: const Text('Web'),
                    selected: previewWidth == 1100,
                    onSelected: (_) => setState(() => previewWidth = 1100),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: previewWidth,
                  decoration: BoxDecoration(
                    border: Border.all(color: NanoColors.textSecondary),
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: senior
                      ? const SeniorHomeFoundation()
                      : const JuniorHomeFoundation(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
""",
    )

    w(
        "packages/nano_design_system/test/nano_responsive_test.dart",
        r"""
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';

void main() {
  test('window size thresholds', () {
    expect(NanoResponsive.windowSizeFor(360), NanoWindowSize.phone);
    expect(NanoResponsive.windowSizeFor(800), NanoWindowSize.tablet);
    expect(NanoResponsive.windowSizeFor(1200), NanoWindowSize.desktop);
  });

  test('junior uses denser grid than senior on phone', () {
    expect(
      NanoResponsive.subjectColumnsFor(size: NanoWindowSize.phone, junior: true),
      2,
    );
    expect(
      NanoResponsive.subjectColumnsFor(size: NanoWindowSize.phone, junior: false),
      1,
    );
  });
}
""",
    )

    w(
        "apps/student_app/test/home_foundation_test.dart",
        r"""
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_testing/nano_testing.dart';
import 'package:student_app/features/home/presentation/junior_home_foundation.dart';
import 'package:student_app/features/home/presentation/senior_home_foundation.dart';

void main() {
  testWidgets('junior and senior render same subject titles', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: NanoTheme.junior(),
        home: const Scaffold(body: JuniorHomeFoundation()),
      ),
    );
    for (final subject in StudentHomeFixtures.subjects) {
      expect(find.text(subject.title), findsOneWidget);
    }

    await tester.pumpWidget(
      MaterialApp(
        theme: NanoTheme.senior(),
        home: const Scaffold(body: SeniorHomeFoundation()),
      ),
    );
    for (final subject in StudentHomeFixtures.subjects) {
      expect(find.text(subject.title), findsOneWidget);
    }
  });

  testWidgets('text scale does not overflow junior home', (tester) async {
    await tester.pumpWidget(
      MediaQuery(
        data: const MediaQueryData(textScaler: TextScaler.linear(1.3)),
        child: MaterialApp(
          theme: NanoTheme.junior(),
          home: const Scaffold(body: SizedBox(width: 360, child: JuniorHomeFoundation())),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    expect(find.textContaining('Hi'), findsOneWidget);
  });
}
""",
    )

    print("FND-03 scaffold written")


if __name__ == "__main__":
    main()
