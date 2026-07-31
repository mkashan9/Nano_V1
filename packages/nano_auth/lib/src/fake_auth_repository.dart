import 'dart:async';

import 'package:nano_domain/nano_domain.dart';

import 'auth_repository.dart';

/// In-memory auth for unit/widget tests (no network).
class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({
    this.validEmail = AuthFixtures.aliEmail,
    this.validPassword = AuthFixtures.aliPassword,
    this.bootstrapBuilder,
  });

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

  final String validEmail;
  final String validPassword;
  final AuthBootstrap Function()? bootstrapBuilder;
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
}

class AuthFailure implements Exception {
  AuthFailure(this.message);
  final String message;

  @override
  String toString() => message;
}
