import 'package:go_router/go_router.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:teacher_app/app/teacher_shell.dart';

GoRouter createTeacherRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
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
          return TeacherShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
          );
        },
        branches: [
          for (final dest in destinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: dest.path,
                  name: dest.id,
                  builder: (context, state) =>
                      TeacherDestinationPage(destination: dest),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}
