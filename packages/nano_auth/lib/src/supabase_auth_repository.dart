import 'dart:async';

import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'auth_repository.dart';
import 'fake_auth_repository.dart';

/// Live Supabase email/password auth + profile/membership bootstrap.
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(
    this.client, {
    this.allowedAccountKinds = const {
      'school_student',
      'independent_student',
    },
    this.appLabel = 'students',
  });

  final SupabaseClient client;
  final Set<String> allowedAccountKinds;
  final String appLabel;
  final _controller = StreamController<bool>.broadcast();
  StreamSubscription<AuthState>? _sub;

  void listen() {
    _sub ??= client.auth.onAuthStateChange.listen((state) {
      _controller.add(state.session != null);
    });
  }

  @override
  Stream<bool> get authStateChanges {
    listen();
    return _controller.stream;
  }

  @override
  Future<AuthBootstrap> signInWithPassword({
    required String email,
    required String password,
  }) async {
    final response = await client.auth.signInWithPassword(
      email: email.trim(),
      password: password,
    );
    final user = response.user;
    if (user == null) {
      throw AuthFailure('Sign-in failed');
    }
    return _bootstrap(user.id);
  }

  @override
  Future<AuthBootstrap?> restoreSession() async {
    final session = client.auth.currentSession;
    final user = session?.user ?? client.auth.currentUser;
    if (user == null) return null;
    return _bootstrap(user.id);
  }

  @override
  Future<void> signOut() async {
    await client.auth.signOut();
  }

  @override
  Future<SignUpResult> signUpIndependent({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final error = SignUpValidator.emailError(email) ??
        SignUpValidator.passwordError(password) ??
        SignUpValidator.displayNameError(displayName);
    if (error != null) {
      throw AuthFailure(error);
    }
    final response = await client.auth.signUp(
      email: email.trim(),
      password: password,
      // The auth.users trigger provisions the profile; clients cannot insert it.
      data: {
        'account_kind': 'independent_student',
        'display_name': displayName.trim(),
      },
    );
    if (response.session == null) {
      return const SignUpResult(bootstrap: null, needsEmailConfirmation: true);
    }
    final user = response.user;
    if (user == null) {
      throw AuthFailure('Signup failed');
    }
    return SignUpResult(
      bootstrap: await _bootstrap(user.id),
      needsEmailConfirmation: false,
    );
  }

  @override
  Future<void> requestPasswordRecovery(String email) async {
    final error = SignUpValidator.emailError(email);
    if (error != null) {
      throw AuthFailure(error);
    }
    // Supabase does not disclose whether the address exists; keep it that way.
    await client.auth.resetPasswordForEmail(email.trim());
  }

  Future<AuthBootstrap> _bootstrap(String userId) async {
    final profileRows = await client
        .from('profiles')
        .select('id, display_name, account_kind, status')
        .eq('id', userId)
        .limit(1);
    if (profileRows.isEmpty) {
      await client.auth.signOut();
      throw AuthFailure('Profile not found for this account');
    }
    final profile = profileRows.first;
    final accountKind = profile['account_kind'] as String? ?? '';
    if (!allowedAccountKinds.contains(accountKind)) {
      await client.auth.signOut();
      throw AuthFailure('This app is for $appLabel only');
    }

    final profileStatus = _membershipStatus(profile['status'] as String?);
    final displayName = (profile['display_name'] as String?)?.trim();
    final name = (displayName == null || displayName.isEmpty)
        ? _defaultName(accountKind)
        : displayName;

    String? schoolId;
    var schoolStatus = SchoolStatus.active;
    var membershipStatus = MembershipStatus.active;

    if (accountKind == 'school_student' ||
        accountKind == 'teacher' ||
        accountKind == 'school_staff') {
      final role = switch (accountKind) {
        'teacher' => 'teacher',
        'school_staff' => 'school_admin',
        _ => 'student',
      };
      final membershipRows = await client
          .from('school_memberships')
          .select('school_id, status, role')
          .eq('user_id', userId)
          .eq('role', role)
          .limit(1);
      if (membershipRows.isEmpty) {
        await client.auth.signOut();
        throw AuthFailure('No school membership found');
      }
      final membership = membershipRows.first;
      schoolId = membership['school_id'] as String?;
      membershipStatus = _membershipStatus(membership['status'] as String?);
      if (schoolId != null) {
        final schoolRows = await client
            .from('schools')
            .select('id, status, name')
            .eq('id', schoolId)
            .limit(1);
        if (schoolRows.isNotEmpty) {
          schoolStatus = _schoolStatus(schoolRows.first['status'] as String?);
        }
      }
    }

    if (accountKind == 'platform') {
      final roleRows = await client
          .from('platform_roles')
          .select('role, revoked_at')
          .eq('user_id', userId)
          .limit(8);
      final active = roleRows.where((row) => row['revoked_at'] == null);
      if (active.isEmpty) {
        await client.auth.signOut();
        throw AuthFailure('No active platform role found');
      }
    }

    final SessionPrincipal principal = switch (accountKind) {
      'independent_student' => SessionPrincipal.independent(displayName: name)
          .copyWith(userId: userId, isAuthenticated: true),
      'teacher' => SessionPrincipal.teacher(displayName: name).copyWith(
          userId: userId,
          schoolId: schoolId,
          isAuthenticated: true,
        ),
      'school_staff' => SessionPrincipal.schoolAdmin(displayName: name).copyWith(
          userId: userId,
          schoolId: schoolId,
          isAuthenticated: true,
        ),
      'platform' => SessionPrincipal.superadmin(displayName: name).copyWith(
          userId: userId,
          isAuthenticated: true,
        ),
      _ => SessionPrincipal.junior(displayName: name).copyWith(
          userId: userId,
          schoolId: schoolId,
          isAuthenticated: true,
        ),
    };

    return AuthBootstrap(
      principal: principal,
      schoolStatus: schoolStatus,
      profileStatus: profileStatus,
      membershipStatus: membershipStatus,
    );
  }

  static String _defaultName(String accountKind) => switch (accountKind) {
        'teacher' => 'Teacher',
        'school_staff' => 'School Admin',
        'platform' => 'Platform Admin',
        _ => 'Student',
      };

  static MembershipStatus _membershipStatus(String? raw) => switch (raw) {
        'suspended' => MembershipStatus.suspended,
        'left' => MembershipStatus.left,
        _ => MembershipStatus.active,
      };

  static SchoolStatus _schoolStatus(String? raw) => switch (raw) {
        'suspended' => SchoolStatus.suspended,
        'archived' => SchoolStatus.archived,
        _ => SchoolStatus.active,
      };
}
