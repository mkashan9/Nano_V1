import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/app/admin_shell.dart';

GoRouter createAdminRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required NanoCopy copy,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  String? initialLocation,
}) {
  final destinations = NavCatalog.visibleFor(principal);
  final resolved = DeepLinkResolver.resolve(
    principal,
    initialLocation ?? '/',
  ).location;

  return GoRouter(
    initialLocation: resolved,
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
          return AdminShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
            copy: copy,
          );
        },
        branches: [
          for (final dest in destinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: dest.path,
                  name: dest.id,
                  builder: (context, state) => AdminDestinationPage(
                    destination: dest,
                    principal: principal,
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
