import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';

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
            const NanoOfflineBanner(),
            const SizedBox(height: NanoSpacing.xl),
            Text('States', style: theme.textTheme.titleLarge),
            const SizedBox(height: 120, child: NanoLoadingState()),
            const SizedBox(height: 160, child: NanoEmptyState()),
            SizedBox(
              height: 180,
              child: NanoErrorState(onRetry: () {}),
            ),
            const SizedBox(height: 160, child: NanoSuspendedState()),
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
