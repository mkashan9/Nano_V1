import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/fixtures/student_home_fixtures.dart';
import 'package:student_app/features/home/presentation/junior_home_page.dart';

/// Whether the app was launched with `--dart-define=NANO_SCREENSHOT_MODE=true`.
bool nanoScreenshotModeEnabled() =>
    const bool.fromEnvironment('NANO_SCREENSHOT_MODE', defaultValue: false);

/// Deterministic Junior Home shell for VIS-01 visual capture (not in prod nav).
class ScreenshotJuniorHomePage extends StatelessWidget {
  const ScreenshotJuniorHomePage({
    super.key,
    this.repository,
    this.useVisualAssets = true,
  });

  final StudentHomeRepository? repository;
  final bool useVisualAssets;

  @override
  Widget build(BuildContext context) {
    final repo = repository ??
        FakeStudentHomeRepository(
          subjects: StudentHomeFixtures.subjects,
          missions: const [],
        );
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: NanoColors.canvas,
        body: SafeArea(
          bottom: false,
          child: JuniorHomePage(
            repository: repo,
            learnerName: StudentHomeFixtures.studentName,
            userId: 'screenshot-junior',
            showCompanionStage: false,
            showMissions: false,
            useVisualAssets: useVisualAssets,
          ),
        ),
        bottomNavigationBar: Material(
          color: NanoColors.canvasElevated,
          child: SafeArea(
            top: false,
            child: SizedBox(
              height: 72,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _NavItem(
                    icon: Icons.home,
                    label: copy.home,
                    selected: true,
                  ),
                  const _NavItem(icon: Icons.menu_book_outlined, label: 'Learn'),
                  const _NavItem(
                    icon: Icons.emoji_events_outlined,
                    label: 'Games',
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    avatar: useVisualAssets
                        ? const AssetImage(JuniorHomeVisualAssets.avatar)
                        : null,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _NavItem extends StatelessWidget {
  const _NavItem({
    required this.icon,
    required this.label,
    this.selected = false,
    this.avatar,
  });

  final IconData icon;
  final String label;
  final bool selected;
  final ImageProvider? avatar;

  @override
  Widget build(BuildContext context) {
    final color = selected ? const Color(0xFF9B6DFF) : Colors.grey.shade500;
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (avatar != null)
          CircleAvatar(radius: 12, backgroundImage: avatar)
        else
          Icon(icon, color: color),
        const SizedBox(height: 4),
        Text(label, style: TextStyle(color: color, fontSize: 12)),
      ],
    );
  }
}
