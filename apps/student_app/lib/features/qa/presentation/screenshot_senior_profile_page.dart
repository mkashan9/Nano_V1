import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/home/visual/senior_home_visual_assets.dart';
import 'package:student_app/features/profile/presentation/senior_profile_page.dart';

/// Deterministic Senior Profile shell for VIS-08 visual capture.
class ScreenshotSeniorProfilePage extends StatelessWidget {
  const ScreenshotSeniorProfilePage({
    super.key,
    this.repository,
    this.useVisualAssets = true,
  });

  final StudentProfileRepository? repository;
  final bool useVisualAssets;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final principal = SessionPrincipal.seniorSchool(displayName: 'Ayaan')
        .copyWith(userId: TenancyFixtures.aliAlphaId);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: NanoColors.canvas,
        body: SafeArea(
          bottom: false,
          child: SeniorProfilePage(
            repository: repository ?? FakeStudentProfileRepository(),
            principal: principal,
            preferences: StudentPreferences(userId: principal.userId!),
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
                  _NavItem(icon: Icons.home_outlined, label: copy.home),
                  const _NavItem(icon: Icons.menu_book_outlined, label: 'Learn'),
                  const _NavItem(
                    icon: Icons.sports_esports_outlined,
                    label: 'Games',
                  ),
                  const _NavItem(
                    icon: Icons.groups_outlined,
                    label: 'Communities',
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    selected: true,
                    avatar: useVisualAssets
                        ? const AssetImage(SeniorHomeVisualAssets.avatar)
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
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: const Color(0xFF9B6DFF), width: 2),
            ),
            child: CircleAvatar(radius: 12, backgroundImage: avatar),
          )
        else
          Icon(icon, color: color, size: 22),
        const SizedBox(height: 4),
        Text(
          label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(color: color, fontSize: 9),
        ),
      ],
    );
  }
}
