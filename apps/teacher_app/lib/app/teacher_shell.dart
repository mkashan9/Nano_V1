import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class TeacherShell extends StatelessWidget {
  const TeacherShell({
    super.key,
    required this.config,
    required this.principal,
    required this.navigationShell,
    required this.copy,
    this.onSignOut,
    this.liveAuth = false,
  });

  final EnvironmentConfig config;
  final SessionPrincipal principal;
  final StatefulNavigationShell navigationShell;
  final NanoCopy copy;
  final VoidCallback? onSignOut;
  final bool liveAuth;

  @override
  Widget build(BuildContext context) {
    final destinations = NavCatalog.visibleFor(principal);
    final items = [
      for (final d in destinations)
        NanoBottomNavItem(
          id: d.id,
          label: copy.navLabel(d.id),
          icon: nanoNavIcon(d.iconName),
        ),
    ];
    final index = navigationShell.currentIndex.clamp(0, items.length - 1);

    return NanoScaffold(
      padBody: false,
      appBar: AppBar(
        title: Text('${config.appDisplayName} Teacher'),
        actions: [
          if (liveAuth && onSignOut != null)
            TextButton(onPressed: onSignOut, child: const Text('Sign out')),
          if (config.environment.showDebugTools)
            Padding(
              padding: const EdgeInsets.all(12),
              child: Chip(label: Text(config.environment.name.toUpperCase())),
            ),
        ],
      ),
      body: navigationShell,
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

class TeacherDestinationPage extends StatelessWidget {
  const TeacherDestinationPage({super.key, required this.destination});

  final NavDestination destination;

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      padBody: true,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              destination.label,
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: NanoSpacing.sm),
            const Text('Teacher shell foundation — workflows arrive later.'),
          ],
        ),
      ),
    );
  }
}
