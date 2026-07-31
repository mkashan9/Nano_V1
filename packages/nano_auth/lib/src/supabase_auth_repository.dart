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
        ? (accountKind == 'teacher' ? 'Teacher' : 'Student')
        : displayName;

    String? schoolId;
    var schoolStatus = SchoolStatus.active;
    var membershipStatus = MembershipStatus.active;

    if (accountKind == 'school_student' || accountKind == 'teacher') {
      final role = accountKind == 'teacher' ? 'teacher' : 'student';
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

    final SessionPrincipal principal = switch (accountKind) {
      'independent_student' => SessionPrincipal.independent(displayName: name)
          .copyWith(userId: userId, isAuthenticated: true),
      'teacher' => SessionPrincipal.teacher(displayName: name).copyWith(
          userId: userId,
          schoolId: schoolId,
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
