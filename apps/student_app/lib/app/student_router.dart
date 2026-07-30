import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/student_shell.dart';

GoRouter createStudentRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  String? initialLocation,
}) {
  final destinations = NavCatalog.visibleFor(principal);
  final resolvedInitial = DeepLinkResolver.resolve(
    principal,
    initialLocation ?? '/',
  ).location;

  return GoRouter(
    initialLocation: resolvedInitial,
    redirect: (context, state) {
      final resolution =
          DeepLinkResolver.resolve(principal, state.uri.path);
      if (resolution.fellBack && resolution.location != state.uri.path) {
        return resolution.location;
      }
      return null;
    },
    routes: [
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return StudentShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
          );
        },
        branches: [
          for (final dest in destinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: dest.path == '/' ? '/' : dest.path,
                  name: dest.id,
                  builder: (context, state) =>
                      _pageFor(dest.id, principal),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

Widget _pageFor(String id, SessionPrincipal principal) {
  return switch (id) {
    'home' || 'learning' => StudentLearningTab(principal: principal),
    'game' || 'games' => const StudentGamesTab(),
    'flex' => const StudentFlexTab(),
    'communities' => const StudentCommunitiesTab(),
    'profile' => StudentProfileTab(principal: principal),
    _ => Center(child: Text('Unknown tab: $id')),
  };
}
