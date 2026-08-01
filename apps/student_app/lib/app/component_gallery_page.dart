import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// Fixed so the gallery shows every reaction instead of hiding some behind a
/// cooldown.
final _galleryClock = DateTime.utc(2026, 1, 1);

class ComponentGalleryPage extends StatefulWidget {
  const ComponentGalleryPage({super.key});

  @override
  State<ComponentGalleryPage> createState() => _ComponentGalleryPageState();
}

class _ComponentGalleryPageState extends State<ComponentGalleryPage> {
  bool senior = false;

  @override
  Widget build(BuildContext context) {
    final theme = senior ? NanoTheme.senior() : NanoTheme.junior();
    return Theme(
      data: theme,
      child: NanoScaffold(
        appBar: AppBar(
          title: const Text('Component gallery'),
          actions: [
            Row(
              children: [
                Text(senior ? 'Senior' : 'Junior'),
                Switch(
                  value: senior,
                  onChanged: (v) => setState(() => senior = v),
                ),
              ],
            ),
          ],
        ),
        body: ListView(
          children: [
            const SizedBox(height: NanoSpacing.md),
            const XpChip(xp: 560),
            const SizedBox(height: NanoSpacing.md),
            const CompanionSlot(),
            const SizedBox(height: NanoSpacing.md),
            // CMP-01: every core reaction, at the density this experience uses.
            for (final event in const [
              CompanionEvent.home,
              CompanionEvent.learningEntry,
              CompanionEvent.quizQuestion,
              CompanionEvent.resultNeedsReview,
              CompanionEvent.resultPassed,
              CompanionEvent.idle,
            ])
              Padding(
                padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                child: CompanionStage(
                  reaction: CompanionRuntime.forExperience(junior: !senior)
                      .notify(event, now: _galleryClock)
                      .reaction,
                ),
              ),
            const SizedBox(height: NanoSpacing.md),
            if (!senior)
              JuniorActionCard(
                title: 'Math',
                subtitle: 'Numbers adventure',
                backgroundColor: NanoColors.worldMath,
                onTap: () {},
              )
            else
              const SeniorProgressCard(
                title: 'Genetics: The Code of Life',
                tag: 'Science',
                progress: 0.65,
                meta: '45 min',
              ),
            const SizedBox(height: NanoSpacing.md),
            const NanoOfflineBanner(lastUpdatedLabel: '2 min ago'),
            const SizedBox(height: NanoSpacing.sm),
            const NanoSyncStatusBanner(phase: NanoSyncPhase.syncing),
            const SizedBox(height: NanoSpacing.sm),
            NanoSyncStatusBanner(
              phase: NanoSyncPhase.failed,
              onRetry: () {},
            ),
            const SizedBox(height: NanoSpacing.xl),
            Text('States', style: theme.textTheme.titleLarge),
            const SizedBox(height: 120, child: NanoLoadingState()),
            const SizedBox(height: 160, child: NanoEmptyState()),
            SizedBox(
              height: 180,
              child: NanoErrorState(onRetry: () {}),
            ),
            const SizedBox(height: 160, child: NanoSuspendedState()),
            const SizedBox(height: 160, child: NanoMaintenanceState()),
            const SizedBox(height: 160, child: NanoPermissionDeniedState()),
            const SizedBox(height: 160, child: NanoFeatureDisabledState()),
            const SizedBox(height: NanoSpacing.xl),
            AdminMetricCard(
              label: 'Active schools',
              value: '12',
              icon: Icons.school_outlined,
            ),
            const SizedBox(height: NanoSpacing.md),
            TeacherTaskCard(
              title: 'Take attendance',
              subtitle: 'Class 5-A · Today',
              onTap: () {},
            ),
            const SizedBox(height: NanoSpacing.xxl),
          ],
        ),
      ),
    );
  }
}
