import 'dart:async';

import 'package:nano_domain/nano_domain.dart';

import 'auth_repository.dart';

/// In-memory student auth for unit/widget tests (no network).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.validEmail = AuthFixtures.aliEmail,
    this.validPassword = AuthFixtures.aliPassword,
  });

  final String validEmail;
  final String validPassword;
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
    _session = AuthBootstrap(
      principal: SessionPrincipal.junior(
        displayName: 'Ali',
      ).copyWith(
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
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
