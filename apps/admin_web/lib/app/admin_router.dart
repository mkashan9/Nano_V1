import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:admin_web/app/admin_shell.dart';
import 'package:admin_web/features/auth/presentation/admin_sign_in_page.dart';

GoRouter createAdminRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required NanoCopy copy,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  String? initialLocation,
  AuthRepository? authRepository,
  bool requireAuth = false,
  AuthBootstrap? authBootstrap,
  ValueChanged<AuthBootstrap>? onAuthBootstrap,
  VoidCallback? onSignedOut,
}) {
  final destinations = NavCatalog.visibleFor(principal);
  final authenticated = !requireAuth || principal.isAuthenticated;
  final blocked = authBootstrap?.isBlocked ?? false;
  final resolvedInitial = !authenticated
      ? '/sign-in'
      : blocked
          ? '/blocked'
          : DeepLinkResolver.resolve(
              principal,
              initialLocation ?? '/',
            ).location;

  return GoRouter(
    initialLocation: resolvedInitial,
    redirect: (context, state) {
      final path = state.uri.path;
      if (requireAuth && !principal.isAuthenticated) {
        return path == '/sign-in' ? null : '/sign-in';
      }
      if (requireAuth &&
          principal.isAuthenticated &&
          (authBootstrap?.isBlocked ?? false) &&
          path != '/blocked') {
        return '/blocked';
      }
      if (requireAuth && principal.isAuthenticated && path == '/sign-in') {
        return '/';
      }
      if (!principal.isAuthenticated) return null;
      final resolution = DeepLinkResolver.resolve(principal, path);
      if (resolution.fellBack && resolution.location != path) {
        return resolution.location;
      }
      return null;
    },
    routes: [
      GoRoute(
        path: '/sign-in',
        builder: (context, state) {
          final repo = authRepository;
          if (repo == null) {
            return const Scaffold(
              body: Center(child: Text('Sign-in is unavailable')),
            );
          }
          return AdminSignInPage(
            authRepository: repo,
            onSignedIn: (bootstrap) {
              onAuthBootstrap?.call(bootstrap);
              onPrincipalChanged(bootstrap.principal);
            },
          );
        },
      ),
      GoRoute(
        path: '/blocked',
        builder: (context, state) {
          return Scaffold(
            body: Column(
              children: [
                const Expanded(
                  child: NanoViewStateHost(
                    state: NanoViewSuspended(),
                    child: SizedBox.shrink(),
                  ),
                ),
                if (onSignedOut != null)
                  SafeArea(
                    child: TextButton(
                      onPressed: onSignedOut,
                      child: const Text('Sign out'),
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AdminShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
            copy: copy,
            onSignOut: onSignedOut,
            liveAuth: requireAuth,
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
