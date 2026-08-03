import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:student_app/features/communities/fixtures/senior_communities_visual_fixtures.dart';
import 'package:student_app/features/communities/visual/senior_communities_visual_assets.dart';

/// Senior Communities visual surface (VIS-09) — reference-matched layout.
class SeniorCommunitiesPage extends StatelessWidget {
  const SeniorCommunitiesPage({
    super.key,
    this.useVisualAssets = true,
    this.onSearch,
    this.onNotifications,
    this.onJoinChallenge,
    this.onCreateProject,
  });

  final bool useVisualAssets;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;
  final VoidCallback? onJoinChallenge;
  final VoidCallback? onCreateProject;

  @override
  Widget build(BuildContext context) {
    void snack(String message) {
      ScaffoldMessenger.maybeOf(context)?.showSnackBar(
        SnackBar(content: Text(message)),
      );
    }

    return ColoredBox(
      color: NanoColors.canvas,
      child: ListView(
        padding: const EdgeInsets.only(bottom: NanoSpacing.xxl),
        children: [
          const SizedBox(height: NanoSpacing.md),
          SeniorCommunitiesHeader(
            title: SeniorCommunitiesVisualFixtures.title,
            subtitlePrefix: SeniorCommunitiesVisualFixtures.subtitlePrefix,
            subtitleAccent: SeniorCommunitiesVisualFixtures.subtitleAccent,
            onSearch: onSearch ?? () => snack('Search communities'),
            onNotifications:
                onNotifications ?? () => snack('Notifications'),
          ),
          const SizedBox(height: NanoSpacing.md),
          SeniorWeeklyChallengeHero(
            eyebrow: SeniorCommunitiesVisualFixtures.challengeEyebrow,
            headline: SeniorCommunitiesVisualFixtures.challengeHeadline,
            headlineAccent:
                SeniorCommunitiesVisualFixtures.challengeHeadlineAccent,
            body: SeniorCommunitiesVisualFixtures.challengeBody,
            challenges: SeniorCommunitiesVisualFixtures.challenges,
            ctaLabel: SeniorCommunitiesVisualFixtures.challengeCta,
            timerLabel: SeniorCommunitiesVisualFixtures.challengeTimer,
            rewardLabel: SeniorCommunitiesVisualFixtures.challengeReward,
            joinersLabel: SeniorCommunitiesVisualFixtures.challengeJoiners,
            illustration: useVisualAssets
                ? const AssetImage(SeniorCommunitiesVisualAssets.challengeHero)
                : null,
            onJoin: onJoinChallenge ?? () => snack('Join Challenge'),
          ),
          const SizedBox(height: NanoSpacing.lg),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Find a Team',
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
            height: 188,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
              itemCount: SeniorCommunitiesVisualFixtures.teams.length,
              separatorBuilder: (_, __) => const SizedBox(width: NanoSpacing.sm),
              itemBuilder: (context, index) {
                final t = SeniorCommunitiesVisualFixtures.teams[index];
                return SeniorTeamCard(
                  title: t.title,
                  needsLabel: t.needs,
                  membersLabel: t.members,
                  ctaLabel: 'Join Team',
                  accent: t.accent,
                  icon: t.icon,
                  onJoin: () => snack('Join ${t.title}'),
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
                    'Builder Clubs',
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
            padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: SeniorCommunitiesVisualFixtures.clubs.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: NanoSpacing.sm,
                crossAxisSpacing: NanoSpacing.sm,
                childAspectRatio: 1.05,
              ),
              itemBuilder: (context, index) {
                final c = SeniorCommunitiesVisualFixtures.clubs[index];
                return SeniorClubCard(
                  title: c.title,
                  membersLabel: c.members,
                  ctaLabel: 'Join Club',
                  accent: c.accent,
                  icon: c.icon,
                  onJoin: () => snack('Join ${c.title}'),
                );
              },
            ),
          ),
          const SizedBox(height: NanoSpacing.lg),
          SeniorStartProjectCard(
            eyebrow: SeniorCommunitiesVisualFixtures.startEyebrow,
            title: SeniorCommunitiesVisualFixtures.startTitle,
            titleAccent: SeniorCommunitiesVisualFixtures.startTitleAccent,
            bullets: SeniorCommunitiesVisualFixtures.startBullets,
            ctaLabel: SeniorCommunitiesVisualFixtures.startCta,
            illustration: useVisualAssets
                ? const AssetImage(SeniorCommunitiesVisualAssets.startProject)
                : null,
            onCreate: onCreateProject ?? () => snack('Create Project'),
          ),
        ],
      ),
    );
  }
}
