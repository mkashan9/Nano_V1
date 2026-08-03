import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/student_auth_redirect.dart';

void main() {
  final junior = SessionPrincipal.junior(displayName: 'Ali')
      .copyWith(userId: 'u1', isAuthenticated: true);

  test('onboarding path does not bounce back to home', () {
    expect(
      studentAuthRedirect(
        path: '/onboarding',
        requireAuth: true,
        isAuthenticated: true,
        isBlocked: false,
        needsOnboarding: true,
        principal: junior,
      ),
      isNull,
    );
  });

  test('incomplete onboarding from home goes to onboarding once', () {
    expect(
      studentAuthRedirect(
        path: '/',
        requireAuth: true,
        isAuthenticated: true,
        isBlocked: false,
        needsOnboarding: true,
        principal: junior,
      ),
      '/onboarding',
    );
  });

  test('completed onboarding leaves the gate for home', () {
    expect(
      studentAuthRedirect(
        path: '/onboarding',
        requireAuth: true,
        isAuthenticated: true,
        isBlocked: false,
        needsOnboarding: false,
        principal: junior,
      ),
      '/',
    );
  });

  test('unknown deep links still fall back without touching onboarding', () {
    expect(
      studentAuthRedirect(
        path: '/not-a-real-tab',
        requireAuth: true,
        isAuthenticated: true,
        isBlocked: false,
        needsOnboarding: false,
        principal: junior,
      ),
      '/',
    );
  });

  test('screenshot routes bypass auth and onboarding gates', () {
    expect(
      studentAuthRedirect(
        path: '/screenshot/junior_home',
        requireAuth: true,
        isAuthenticated: false,
        isBlocked: false,
        needsOnboarding: true,
        principal: junior,
      ),
      isNull,
    );
  });
}
