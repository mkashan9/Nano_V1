import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/component_gallery_page.dart';
import 'package:student_app/app/states_preview_page.dart';
import 'package:student_app/app/locale_preview_page.dart';
import 'package:student_app/app/diagnostics_page.dart';
import 'package:student_app/app/environment_badge.dart';
import 'package:student_app/app/nav_placeholder_page.dart';
import 'package:student_app/features/home/presentation/junior_home_foundation.dart';
import 'package:student_app/features/home/presentation/responsive_preview_page.dart';
import 'package:student_app/features/home/presentation/senior_home_foundation.dart';

class StudentShell extends StatelessWidget {
  const StudentShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.onPrincipalChanged,
    required this.onLocaleChanged,
    required this.locale,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final ValueChanged<SessionPrincipal> onPrincipalChanged;
  final ValueChanged<NanoAppLocale> onLocaleChanged;
  final NanoAppLocale locale;

  @override
  Widget build(BuildContext context) {
    final destinations = NavCatalog.visibleFor(principal);
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final junior = principal.role.usesJuniorPresentation;
    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: copy.studentNavLabel(d.id, junior: junior),
          icon: nanoNavIcon(d.iconName),
        ),
    ];

    final index = navigationShell.currentIndex.clamp(0, items.length - 1);

    return NanoScaffold(
      padBody: false,
      appBar: AppBar(
        title: Text(config.appDisplayName),
        actions: [
          if (config.environment.showDebugTools)
            EnvironmentBadge(environment: config.environment),
        ],
      ),
      body: Column(
        children: [
          if (config.environment.showDebugTools)
            Material(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(
                  horizontal: NanoSpacing.sm,
                  vertical: NanoSpacing.xs,
                ),
                child: Row(
                  children: [
                    DropdownButtonHideUnderline(
                      child: DropdownButton<NanoAppLocale>(
                        value: locale,
                        items: const [
                          DropdownMenuItem(
                            value: NanoAppLocale.en,
                            child: Text('EN'),
                          ),
                          DropdownMenuItem(
                            value: NanoAppLocale.ur,
                            child: Text('UR'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) onLocaleChanged(value);
                        },
                      ),
                    ),
                    const SizedBox(width: NanoSpacing.sm),
                    DropdownButtonHideUnderline(
                      child: DropdownButton<AppRole>(
                        value: principal.role,
                        items: const [
                          DropdownMenuItem(
                            value: AppRole.juniorStudent,
                            child: Text('Junior'),
                          ),
                          DropdownMenuItem(
                            value: AppRole.seniorStudent,
                            child: Text('Senior'),
                          ),
                          DropdownMenuItem(
                            value: AppRole.independentStudent,
                            child: Text('Independent'),
                          ),
                        ],
                        onChanged: (role) {
                          if (role == null) return;
                          final next = switch (role) {
                            AppRole.juniorStudent => SessionPrincipal.junior(),
                            AppRole.seniorStudent =>
                              SessionPrincipal.seniorSchool(),
                            AppRole.independentStudent =>
                              SessionPrincipal.independent(),
                            _ => principal,
                          };
                          onPrincipalChanged(next);
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(child: navigationShell),
          if (config.environment.showDebugTools)
            SafeArea(
              top: false,
              child: Padding(
                padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                child: Wrap(
                  spacing: NanoSpacing.sm,
                  alignment: WrapAlignment.center,
                  children: [
                    if (config.isFeatureEnabled('diagnostics'))
                      TextButton(
                        onPressed: () {
                          Navigator.of(context).push(
                            MaterialPageRoute<void>(
                              builder: (_) =>
                                  DiagnosticsPage(config: config),
                            ),
                          );
                        },
                        child: const Text('Diagnostics'),
                      ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ComponentGalleryPage(),
                          ),
                        );
                      },
                      child: const Text('Gallery'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const StatesPreviewPage(),
                          ),
                        );
                      },
                      child: const Text('UI states'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const LocalePreviewPage(),
                          ),
                        );
                      },
                      child: const Text('Locale'),
                    ),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => const ResponsivePreviewPage(),
                          ),
                        );
                      },
                      child: const Text('Responsive preview'),
                    ),
                    TextButton(
                      onPressed: () {
                        // Simulate a notification deep link to Flex.
                        final resolved =
                            DeepLinkResolver.resolve(principal, '/flex');
                        context.go(resolved.location);
                        if (resolved.fellBack && context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Flex unavailable — opened Home instead',
                              ),
                            ),
                          );
                        }
                      },
                      child: const Text('Deep link: Flex'),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
      bottomNavigationBar: NanoBottomNav(
        items: items,
        selectedIndex: index,
        onSelect: (i) => navigationShell.goBranch(
          i,
          initialLocation: i == navigationShell.currentIndex,
        ),
      ),
    );
  }
}

class StudentLearningTab extends StatelessWidget {
  const StudentLearningTab({super.key, required this.principal});

  final SessionPrincipal principal;

  @override
  Widget build(BuildContext context) {
    if (principal.role.usesJuniorPresentation) {
      return const JuniorHomeFoundation();
    }
    return const SeniorHomeFoundation();
  }
}

class StudentGamesTab extends StatelessWidget {
  const StudentGamesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(title: 'Games');
  }
}

class StudentFlexTab extends StatelessWidget {
  const StudentFlexTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(
      title: 'Flex',
      subtitle: 'School-eligible students only. Independent students never see this tab.',
    );
  }
}

class StudentCommunitiesTab extends StatelessWidget {
  const StudentCommunitiesTab({super.key});

  @override
  Widget build(BuildContext context) {
    return const NavPlaceholderPage(title: 'Communities');
  }
}

class StudentProfileTab extends StatelessWidget {
  const StudentProfileTab({super.key, required this.principal});

  final SessionPrincipal principal;

  @override
  Widget build(BuildContext context) {
    return NavPlaceholderPage(
      title: 'Profile',
      subtitle: '${principal.displayName} · ${principal.role.label}',
    );
  }
}
