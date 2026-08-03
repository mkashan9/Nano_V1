import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/profile/fixtures/senior_profile_visual_fixtures.dart';
import 'package:student_app/features/profile/visual/senior_profile_visual_assets.dart';

/// Senior Profile visual surface (VIS-08) — reference-matched layout.
class SeniorProfilePage extends StatefulWidget {
  const SeniorProfilePage({
    super.key,
    required this.repository,
    required this.principal,
    this.preferences,
    this.onPreferencesChanged,
    this.onOpenAccessibility,
    this.useVisualAssets = true,
  });

  final StudentProfileRepository repository;
  final SessionPrincipal principal;
  final StudentPreferences? preferences;
  final ValueChanged<StudentPreferences>? onPreferencesChanged;
  final VoidCallback? onOpenAccessibility;
  final bool useVisualAssets;

  @override
  State<SeniorProfilePage> createState() => _SeniorProfilePageState();
}

class _SeniorProfilePageState extends State<SeniorProfilePage> {
  NanoViewState _state = const NanoViewLoading();
  StudentProfileView? _profile;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final userId = widget.principal.userId ?? TenancyFixtures.aliAlphaId;
      final profile = await widget.repository.loadProfile(
        userId: userId,
        displayName: widget.principal.displayName,
        role: widget.principal.role,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError(message: 'Profile unavailable'));
    }
  }

  @override
  Widget build(BuildContext context) {
    return NanoViewStateHost(
      state: _state,
      onRetry: _load,
      child: _profile == null
          ? const SizedBox.shrink()
          : ColoredBox(
              color: NanoColors.canvas,
              child: ListView(
                padding: const EdgeInsets.only(bottom: NanoSpacing.xxl),
                children: [
                  const SizedBox(height: NanoSpacing.md),
                  SeniorProfileHeader(
                    greeting: SeniorProfileVisualFixtures.greeting,
                    subtitle: SeniorProfileVisualFixtures.subtitle,
                    rankLabel: SeniorProfileVisualFixtures.rankLabel,
                    levelLabel: SeniorProfileVisualFixtures.levelLabel,
                    xpLabel: SeniorProfileVisualFixtures.xpLabel,
                    xpProgress: SeniorProfileVisualFixtures.xpProgress,
                    avatar: widget.useVisualAssets
                        ? const AssetImage(SeniorProfileVisualAssets.avatar)
                        : null,
                    onNotifications: () {},
                    onSettings: widget.onOpenAccessibility,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  SeniorStreakBanner(
                    title:
                        '${SeniorProfileVisualFixtures.streakDays} Day Streak',
                    subtitle: SeniorProfileVisualFixtures.streakSubtitle,
                  ),
                  const SizedBox(height: NanoSpacing.lg),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: SeniorProfileVisualFixtures.metrics.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 2,
                        mainAxisSpacing: NanoSpacing.sm,
                        crossAxisSpacing: NanoSpacing.sm,
                        childAspectRatio: 1.45,
                      ),
                      itemBuilder: (context, index) {
                        final m = SeniorProfileVisualFixtures.metrics[index];
                        return SeniorDashboardStatCard(
                          value: m.value,
                          label: m.label,
                          accent: m.accent,
                          icon: m.icon,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'This Week',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFFB39DFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  SizedBox(
                    height: 160,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: NanoSpacing.md),
                      itemCount: SeniorProfileVisualFixtures.weekGoals.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: NanoSpacing.sm),
                      itemBuilder: (context, index) {
                        final g = SeniorProfileVisualFixtures.weekGoals[index];
                        return SeniorWeekGoalCard(
                          title: g.title,
                          body: g.body,
                          progressLabel: g.progressLabel,
                          xpLabel: g.xpLabel,
                          progress: g.progress,
                          accent: g.accent,
                          icon: g.icon,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Achievements',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFFB39DFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                    child: GridView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount:
                          SeniorProfileVisualFixtures.achievements.length,
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 3,
                        mainAxisSpacing: NanoSpacing.sm,
                        crossAxisSpacing: NanoSpacing.sm,
                        childAspectRatio: 0.95,
                      ),
                      itemBuilder: (context, index) {
                        final a =
                            SeniorProfileVisualFixtures.achievements[index];
                        return SeniorAchievementHexCard(
                          title: a.title,
                          levelLabel: a.level,
                          accent: a.accent,
                          icon: a.icon,
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Top Builders',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 18,
                            ),
                          ),
                        ),
                        Text(
                          'View All',
                          style: TextStyle(
                            color: Color(0xFFB39DFF),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  SizedBox(
                    height: 148,
                    child: ListView.separated(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(
                          horizontal: NanoSpacing.md),
                      itemCount:
                          SeniorProfileVisualFixtures.topBuilders.length,
                      separatorBuilder: (_, __) =>
                          const SizedBox(width: NanoSpacing.sm),
                      itemBuilder: (context, index) {
                        final b =
                            SeniorProfileVisualFixtures.topBuilders[index];
                        return SeniorTopBuilderCard(
                          name: b.name,
                          rankLabel: b.rank,
                          streakLabel: b.streak,
                          ctaLabel: 'Build Together',
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.lg),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: NanoSpacing.md),
                    child: Text(
                      'Learning Journey',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 18,
                      ),
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  SeniorLearningPathsPanel(
                    steps: SeniorProfileVisualFixtures.journey,
                    illustration: widget.useVisualAssets
                        ? const AssetImage(
                            SeniorProfileVisualAssets.journeyPortal)
                        : null,
                  ),
                ],
              ),
            ),
    );
  }
}
