import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:nano_auth/nano_auth.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/app/student_auth_redirect.dart';
import 'package:student_app/app/student_shell.dart';
import 'package:student_app/features/auth/presentation/recover_password_page.dart';
import 'package:student_app/features/auth/presentation/sign_in_page.dart';
import 'package:student_app/features/auth/presentation/sign_up_page.dart';
import 'package:student_app/features/onboarding/presentation/onboarding_flow_page.dart';

GoRouter createStudentRouter({
  required EnvironmentConfig config,
  required SessionPrincipal principal,
  required ValueChanged<SessionPrincipal> onPrincipalChanged,
  required ValueChanged<NanoAppLocale> onLocaleChanged,
  required ValueChanged<AccessibilityPreferences> onAccessibilityChanged,
  required NanoAppLocale locale,
  required AccessibilityPreferences accessibility,
  String? initialLocation,
  AuthRepository? authRepository,
  bool requireAuth = false,
  AuthBootstrap? authBootstrap,
  ValueChanged<AuthBootstrap>? onAuthBootstrap,
  VoidCallback? onSignedOut,
  OnboardingRepository? onboardingRepository,
  OnboardingProgress? onboardingProgress,
  ValueChanged<OnboardingProgress>? onOnboardingChanged,
  void Function(OnboardingProgress progress, ExperienceTrack track)?
      onOnboardingCompleted,
  String? schoolName,
  StudentPreferencesRepository? preferencesRepository,
  StudentPreferences? preferences,
  ValueChanged<StudentPreferences>? onPreferencesChanged,
  StudentHomeRepository? homeRepository,
  StudentProfileRepository? profileRepository,
  LearningCatalogRepository? catalogRepository,
  LearningProgressRepository? progressRepository,
  CheckpointRepository? checkpointRepository,
  LearningInsightsRepository? insightsRepository,
  NanoSyncController? syncController,
}) {
  final destinations = NavCatalog.visibleFor(principal);
  final authenticated = !requireAuth || principal.isAuthenticated;
  final blocked = authBootstrap?.isBlocked ?? false;
  final needsOnboarding = authenticated &&
      !blocked &&
      onboardingRepository != null &&
      onboardingProgress?.isComplete != true;
  final resolvedInitial = !authenticated
      ? '/sign-in'
      : blocked
          ? '/blocked'
          : needsOnboarding
              ? '/onboarding'
              : DeepLinkResolver.resolve(
                  principal,
                  initialLocation ?? '/',
                ).location;

  return GoRouter(
    initialLocation: resolvedInitial,
    redirect: (context, state) {
      return studentAuthRedirect(
        path: state.uri.path,
        requireAuth: requireAuth,
        isAuthenticated: principal.isAuthenticated,
        isBlocked: authBootstrap?.isBlocked ?? false,
        needsOnboarding: needsOnboarding,
        principal: principal,
      );
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
          return SignInPage(
            authRepository: repo,
            onSignedIn: (bootstrap) {
              onAuthBootstrap?.call(bootstrap);
              onPrincipalChanged(bootstrap.principal);
            },
            onCreateAccount: () => context.go('/sign-up'),
            onForgotPassword: () => context.go('/recover'),
          );
        },
      ),
      GoRoute(
        path: '/sign-up',
        builder: (context, state) {
          final repo = authRepository;
          if (repo == null) {
            return const Scaffold(
              body: Center(child: Text('Signup is unavailable')),
            );
          }
          return SignUpPage(
            authRepository: repo,
            onSignedUp: (bootstrap) {
              onAuthBootstrap?.call(bootstrap);
              onPrincipalChanged(bootstrap.principal);
            },
            onBackToSignIn: () => context.go('/sign-in'),
          );
        },
      ),
      GoRoute(
        path: '/recover',
        builder: (context, state) {
          final repo = authRepository;
          if (repo == null) {
            return const Scaffold(
              body: Center(child: Text('Recovery is unavailable')),
            );
          }
          return RecoverPasswordPage(
            authRepository: repo,
            onBackToSignIn: () => context.go('/sign-in'),
          );
        },
      ),
      GoRoute(
        path: '/onboarding',
        builder: (context, state) {
          final repo = onboardingRepository;
          if (repo == null) {
            return const Scaffold(
              body: Center(child: Text('Onboarding is unavailable')),
            );
          }
          return OnboardingFlowPage(
            repository: repo,
            progress: onboardingProgress ??
                OnboardingProgress(userId: principal.userId ?? 'local'),
            principal: principal,
            schoolName: schoolName,
            preferencesRepository: preferencesRepository,
            preferences: preferences,
            onPreferencesChanged: onPreferencesChanged,
            onProgressChanged: (progress) =>
                onOnboardingChanged?.call(progress),
            onCompleted: (progress, track) {
              onOnboardingCompleted?.call(progress, track);
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
          return StudentShell(
            config: config,
            principal: principal,
            navigationShell: navigationShell,
            onPrincipalChanged: onPrincipalChanged,
            onLocaleChanged: onLocaleChanged,
            onAccessibilityChanged: onAccessibilityChanged,
            locale: locale,
            accessibility: accessibility,
            onSignOut: onSignedOut,
            liveAuth: requireAuth,
          );
        },
        branches: [
          for (final dest in destinations)
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: dest.path == '/' ? '/' : dest.path,
                  name: dest.id,
                  builder: (context, state) => _pageFor(
                    context,
                    dest.id,
                    principal,
                    homeRepository: homeRepository,
                    companionName: preferences?.companionName,
                    catalogRepository: catalogRepository,
                    progressRepository: progressRepository,
                    checkpointRepository: checkpointRepository,
                    insightsRepository: insightsRepository,
                    profileRepository: profileRepository,
                    preferences: preferences,
                    onPreferencesChanged: onPreferencesChanged,
                    onAccessibilityChanged: onAccessibilityChanged,
                    onSignOut: onSignedOut,
                    syncController: syncController,
                  ),
                ),
              ],
            ),
        ],
      ),
    ],
  );
}

Widget _pageFor(
  BuildContext context,
  String id,
  SessionPrincipal principal, {
  StudentHomeRepository? homeRepository,
  String? companionName,
  LearningCatalogRepository? catalogRepository,
  LearningProgressRepository? progressRepository,
  CheckpointRepository? checkpointRepository,
  LearningInsightsRepository? insightsRepository,
  StudentProfileRepository? profileRepository,
  StudentPreferences? preferences,
  ValueChanged<StudentPreferences>? onPreferencesChanged,
  ValueChanged<AccessibilityPreferences>? onAccessibilityChanged,
  VoidCallback? onSignOut,
  NanoSyncController? syncController,
}) {
  return switch (id) {
    'home' || 'learning' => StudentLearningTab(
        principal: principal,
        homeRepository: homeRepository,
        catalogRepository: catalogRepository,
        progressRepository: progressRepository,
        checkpointRepository: checkpointRepository,
        insightsRepository: insightsRepository,
        companionName: companionName,
        // Home cards deep-link through the resolver, so an ineligible learner
        // lands somewhere valid instead of on a dead route.
        onOpenFlex: () => _openDeepLink(context, principal, '/flex'),
      ),
    'game' || 'games' => const StudentGamesTab(),
    'flex' => const StudentFlexTab(),
    'communities' => const StudentCommunitiesTab(),
    'profile' => StudentProfileTab(
        principal: principal,
        profileRepository: profileRepository,
        insightsRepository: insightsRepository,
        preferences: preferences,
        onPreferencesChanged: onPreferencesChanged,
        onAccessibilityChanged: onAccessibilityChanged,
        onSignOut: onSignOut,
        syncController: syncController,
      ),
    _ => Center(child: Text('Unknown tab: $id')),
  };
}

void _openDeepLink(
  BuildContext context,
  SessionPrincipal principal,
  String location,
) {
  final resolved = DeepLinkResolver.resolve(principal, location);
  context.go(resolved.location);
  if (resolved.fellBack) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$location is unavailable — opened Home instead')),
    );
  }
}
