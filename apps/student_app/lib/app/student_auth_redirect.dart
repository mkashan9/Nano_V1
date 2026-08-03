import 'package:nano_domain/nano_domain.dart';

/// Pure redirect rules for the student app. Kept free of Flutter so the
/// `/onboarding` ↔ `/` loop can be regression-tested without a widget tree.
String? studentAuthRedirect({
  required String path,
  required bool requireAuth,
  required bool isAuthenticated,
  required bool isBlocked,
  required bool needsOnboarding,
  required SessionPrincipal principal,
}) {
  const gatePaths = {
    '/sign-in',
    '/sign-up',
    '/recover',
    '/onboarding',
    '/blocked',
  };

  // VIS-01 deterministic capture routes — never gated by auth/onboarding.
  if (path.startsWith('/screenshot/')) {
    return null;
  }

  if (requireAuth && !isAuthenticated) {
    return const {'/sign-in', '/sign-up', '/recover'}.contains(path)
        ? null
        : '/sign-in';
  }
  if (requireAuth && isAuthenticated && isBlocked && path != '/blocked') {
    return '/blocked';
  }
  if (requireAuth &&
      isAuthenticated &&
      const {'/sign-in', '/sign-up', '/recover'}.contains(path)) {
    return needsOnboarding ? '/onboarding' : '/';
  }
  if (needsOnboarding && path != '/onboarding') {
    return '/onboarding';
  }
  if (!needsOnboarding && path == '/onboarding') {
    return '/';
  }
  if (!isAuthenticated || gatePaths.contains(path)) {
    return null;
  }
  final resolution = DeepLinkResolver.resolve(principal, path);
  if (resolution.fellBack && resolution.location != path) {
    return resolution.location;
  }
  return null;
}
