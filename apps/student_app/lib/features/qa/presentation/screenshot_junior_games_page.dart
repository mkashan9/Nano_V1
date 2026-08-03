import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/games/presentation/games_catalog_page.dart';

/// Deterministic Junior Games shell for VIS-03 visual capture.
class ScreenshotJuniorGamesPage extends StatelessWidget {
  const ScreenshotJuniorGamesPage({
    super.key,
    this.repository,
    this.useVisualAssets = true,
  });

  final GameCatalogRepository? repository;
  final bool useVisualAssets;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: NanoColors.canvas,
        body: SafeArea(
          bottom: false,
          child: GamesCatalogPage(
            repository: repository ?? FakeGameCatalogRepository(),
            junior: true,
            gradeLevel: 3,
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
                    icon: Icons.sports_esports,
                    label: 'Games',
                    selected: true,
                  ),
                  _NavItem(
                    icon: Icons.person_outline,
                    label: 'Profile',
                    avatar: useVisualAssets
                        ? const AssetImage(
                            'assets/visual/junior/junior_avatar_ali.png',
                          )
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
