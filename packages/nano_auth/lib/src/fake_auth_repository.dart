import 'dart:async';

import 'package:nano_domain/nano_domain.dart';

import 'auth_repository.dart';

/// In-memory auth for unit/widget tests (no network).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.validEmail = AuthFixtures.aliEmail,
    this.validPassword = AuthFixtures.aliPassword,
    this.bootstrapBuilder,
    this.requireEmailConfirmation = false,
    Set<String>? registeredEmails,
  }) : registeredEmails = registeredEmails ?? <String>{};

  factory FakeAuthRepository.teacher() => FakeAuthRepository(
        validEmail: AuthFixtures.teacherEmail,
        validPassword: AuthFixtures.teacherPassword,
        bootstrapBuilder: () => AuthBootstrap(
          principal: SessionPrincipal.teacher(displayName: 'Ms. Khan').copyWith(
            userId: AuthFixtures.teacherUserId,
            schoolId: AuthFixtures.teacherSchoolId,
            isAuthenticated: true,
          ),
          schoolStatus: SchoolStatus.active,
          profileStatus: MembershipStatus.active,
          membershipStatus: MembershipStatus.active,
        ),
      );

  factory FakeAuthRepository.schoolAdmin() => FakeAuthRepository(
        validEmail: AuthFixtures.schoolAdminEmail,
        validPassword: AuthFixtures.schoolAdminPassword,
        bootstrapBuilder: () => AuthBootstrap(
          principal: SessionPrincipal.schoolAdmin(
            displayName: 'Alpha School Admin',
          ).copyWith(
            userId: AuthFixtures.schoolAdminUserId,
            schoolId: AuthFixtures.schoolAdminSchoolId,
            isAuthenticated: true,
          ),
          schoolStatus: SchoolStatus.active,
          profileStatus: MembershipStatus.active,
          membershipStatus: MembershipStatus.active,
        ),
      );

  factory FakeAuthRepository.superadmin() => FakeAuthRepository(
        validEmail: AuthFixtures.platformEmail,
        validPassword: AuthFixtures.platformPassword,
        bootstrapBuilder: () => AuthBootstrap(
          principal: SessionPrincipal.superadmin(
            displayName: 'Platform Admin',
          ).copyWith(
            userId: AuthFixtures.platformUserId,
            isAuthenticated: true,
          ),
          schoolStatus: SchoolStatus.active,
          profileStatus: MembershipStatus.active,
          membershipStatus: MembershipStatus.active,
        ),
      );

  final String validEmail;
  final String validPassword;
  final AuthBootstrap Function()? bootstrapBuilder;
  final bool requireEmailConfirmation;
  final Set<String> registeredEmails;
  final List<String> recoveryRequests = <String>[];
  final _controller = StreamController<bool>.broadcast();
  AuthBootstrap? _session;

  @override
  Stream<bool> get authStateChanges => _controller.stream;

  @override
  Future<AuthBootstrap> signInWithPassword({
    required String email,
    required String password,
  }) async {
    if (email.trim().toLowerCase() != validEmail.toLowerCase() ||
        password != validPassword) {
      throw AuthFailure('Invalid email or password');
    }
    _session = bootstrapBuilder?.call() ??
        AuthBootstrap(
          principal: SessionPrincipal.junior(displayName: 'Ali').copyWith(
            userId: AuthFixtures.aliUserId,
            schoolId: AuthFixtures.aliSchoolId,
            isAuthenticated: true,
          ),
          schoolStatus: SchoolStatus.active,
          profileStatus: MembershipStatus.active,
          membershipStatus: MembershipStatus.active,
        );
    _controller.add(true);
    return _session!;
  }

  @override
  Future<AuthBootstrap?> restoreSession() async => _session;

  @override
  Future<void> signOut() async {
    _session = null;
    _controller.add(false);
  }

  @override
  Future<SignUpResult> signUpIndependent({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final normalized = email.trim().toLowerCase();
    if (registeredEmails.contains(normalized)) {
      throw AuthFailure('An account already exists for this email');
    }
    final error = SignUpValidator.emailError(email) ??
        SignUpValidator.passwordError(password) ??
        SignUpValidator.displayNameError(displayName);
    if (error != null) {
      throw AuthFailure(error);
    }
    registeredEmails.add(normalized);
    if (requireEmailConfirmation) {
      return const SignUpResult(bootstrap: null, needsEmailConfirmation: true);
    }
    _session = AuthBootstrap(
      principal: SessionPrincipal.independent(displayName: displayName.trim())
          .copyWith(userId: AuthFixtures.indieUserId, isAuthenticated: true),
      schoolStatus: SchoolStatus.active,
      profileStatus: MembershipStatus.active,
      membershipStatus: MembershipStatus.active,
    );
    _controller.add(true);
    return SignUpResult(bootstrap: _session, needsEmailConfirmation: false);
  }

  @override
  Future<void> requestPasswordRecovery(String email) async {
    final error = SignUpValidator.emailError(email);
    if (error != null) {
      throw AuthFailure(error);
    }
    recoveryRequests.add(email.trim().toLowerCase());
  }
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}

/// Turns SDK / network exceptions into short copy for the sign-in surfaces.
String describeAuthError(Object error) {
  if (error is AuthFailure) return error.message;
  final text = error.toString().toLowerCase();
  if (text.contains('failed to fetch') ||
      text.contains('authretryablefetchexception') ||
      text.contains('clientexception') ||
      text.contains('socketexception') ||
      text.contains('network is unreachable') ||
      text.contains('connection refused') ||
      text.contains('timed out') ||
      text.contains('timeout')) {
    return 'Could not reach Nano servers. Check your connection and try again.';
  }
  if (text.contains('invalid login') ||
      text.contains('invalid_credentials') ||
      text.contains('invalid email or password')) {
    return 'Email or password is incorrect.';
  }
  if (text.contains('email not confirmed')) {
    return 'Confirm your email, then sign in again.';
  }
  return 'Something went wrong. Try again.';
}
