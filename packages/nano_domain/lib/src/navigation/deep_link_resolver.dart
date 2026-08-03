import 'nav_catalog.dart';
import 'nav_destination.dart';
import 'session_principal.dart';

class DeepLinkResolution {
  const DeepLinkResolution({
    required this.location,
    required this.fellBack,
    this.requestedPath,
  });

  final String location;
  final bool fellBack;
  final String? requestedPath;
}

abstract final class DeepLinkResolver {
  /// Resolves a notification/deep-link path to a permitted location.
  /// Unavailable targets fall back to a safe parent (usually home `/`).
  static DeepLinkResolution resolve(
    SessionPrincipal principal,
    String requestedPath,
  ) {
    final normalized = _normalize(requestedPath);
    final catalog = NavCatalog.catalogFor(principal.role);
    final match = _find(catalog, normalized);

    if (match == null) {
      return DeepLinkResolution(
        location: principal.homePath,
        fellBack: true,
        requestedPath: normalized,
      );
    }

    if (!RouteAccess.canAccess(principal, match)) {
      return DeepLinkResolution(
        location: match.fallbackPath,
        fellBack: true,
        requestedPath: normalized,
      );
    }

    return DeepLinkResolution(
      location: match.path,
      fellBack: false,
      requestedPath: normalized,
    );
  }

  static String _normalize(String path) {
    if (path.isEmpty) return '/';
    var p = path.trim();
    if (!p.startsWith('/')) p = '/$p';
    if (p.length > 1 && p.endsWith('/')) p = p.substring(0, p.length - 1);
    // NOT-01: older notification templates / seeds use these aliases.
    if (p == '/me') return '/profile';
    return p;
  }

  static NavDestination? _find(List<NavDestination> catalog, String path) {
    for (final d in catalog) {
      if (d.path == path) return d;
    }
    // FLX-01: /flex/marks (and siblings) land on the Flex hub when eligible.
    if (path == '/flex' || path.startsWith('/flex/')) {
      for (final d in catalog) {
        if (d.path == '/flex') return d;
      }
    }
    return null;
  }
}
