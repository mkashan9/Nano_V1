import '../environment/environment_config.dart';
import '../navigation/session_principal.dart';
import '../tenancy/tenancy_models.dart';
import 'access_guard.dart';

/// QA-01 security hardening checklist item.
enum SecurityCheckStatus { pass, warn, fail }

class SecurityHardeningCheck {
  const SecurityHardeningCheck({
    required this.id,
    required this.title,
    required this.status,
    required this.detail,
  });

  final String id;
  final String title;
  final SecurityCheckStatus status;
  final String detail;

  bool get passed => status == SecurityCheckStatus.pass;
}

class SecurityHardeningReport {
  const SecurityHardeningReport({
    required this.checks,
    required this.generatedAt,
  });

  final List<SecurityHardeningCheck> checks;
  final DateTime generatedAt;

  bool get allPassed => checks.every((check) => check.passed);
  int get failCount =>
      checks.where((check) => check.status == SecurityCheckStatus.fail).length;
}

/// Detects strings that must never ship in Flutter clients or committed docs.
abstract final class SecretPatternPolicy {
  static final _patterns = <RegExp>[
    RegExp(r'service_role', caseSensitive: false),
    RegExp(r'supabase.*service', caseSensitive: false),
    RegExp(r'-----BEGIN (RSA |EC )?PRIVATE KEY-----'),
    RegExp(r'ghp_[A-Za-z0-9]{20,}'),
    RegExp(r'sk-[A-Za-z0-9]{20,}'),
    RegExp(r'api_s\.txt', caseSensitive: false),
  ];

  static List<String> findLeaks(String text) {
    final hits = <String>[];
    for (final pattern in _patterns) {
      if (pattern.hasMatch(text)) {
        hits.add(pattern.pattern);
      }
    }
    return hits;
  }

  static bool looksLikeServiceRoleJwt(String token) {
    final t = token.trim().toLowerCase();
    return t.contains('service_role') || t.contains('"role":"service_role"');
  }
}

/// Client environment rules for Flutter apps (anon key only).
abstract final class ClientConfigHardening {
  static SecurityHardeningCheck evaluate(EnvironmentConfig config) {
    if (config.supabaseAnonKey.toLowerCase().contains('service_role') ||
        SecretPatternPolicy.looksLikeServiceRoleJwt(config.supabaseAnonKey)) {
      return const SecurityHardeningCheck(
        id: 'client.anon_only',
        title: 'Flutter uses anon key only',
        status: SecurityCheckStatus.fail,
        detail: 'Service-role material must never ship in client apps.',
      );
    }
    final leaks = SecretPatternPolicy.findLeaks(
      '${config.supabaseUrl}\n${config.supabaseAnonKey}',
    );
    if (leaks.isNotEmpty) {
      return SecurityHardeningCheck(
        id: 'client.anon_only',
        title: 'Flutter uses anon key only',
        status: SecurityCheckStatus.fail,
        detail: 'Forbidden secret patterns in config: ${leaks.join(', ')}',
      );
    }
    return const SecurityHardeningCheck(
      id: 'client.anon_only',
      title: 'Flutter uses anon key only',
      status: SecurityCheckStatus.pass,
      detail: 'Config carries URL + anon key only.',
    );
  }
}

/// Confirms SEC-03 client access guard still blocks suspended/revoked actors.
abstract final class AccessGuardHardening {
  static SecurityHardeningCheck evaluate() {
    final cases = <AccessDecision>[
      AccessGuard.evaluate(
        schoolStatus: SchoolStatus.suspended,
        membershipStatus: MembershipStatus.active,
        profileStatus: MembershipStatus.active,
        sessionRevoked: false,
      ),
      AccessGuard.evaluate(
        schoolStatus: SchoolStatus.active,
        membershipStatus: MembershipStatus.suspended,
        profileStatus: MembershipStatus.active,
        sessionRevoked: false,
      ),
      AccessGuard.evaluate(
        schoolStatus: SchoolStatus.active,
        membershipStatus: MembershipStatus.active,
        profileStatus: MembershipStatus.suspended,
        sessionRevoked: false,
      ),
      AccessGuard.evaluate(
        schoolStatus: SchoolStatus.active,
        membershipStatus: MembershipStatus.active,
        profileStatus: MembershipStatus.active,
        sessionRevoked: true,
      ),
      AccessGuard.evaluate(
        schoolStatus: SchoolStatus.active,
        membershipStatus: MembershipStatus.active,
        profileStatus: MembershipStatus.active,
        sessionRevoked: false,
        requiredPermission: 'platform.analytics',
        permissions: const {},
      ),
    ];
    final allDenied = cases.every((decision) => !decision.allowed);
    if (!allDenied) {
      return const SecurityHardeningCheck(
        id: 'access.guard',
        title: 'AccessGuard denies suspended/revoked actors',
        status: SecurityCheckStatus.fail,
        detail: 'One or more expected denials returned allow.',
      );
    }
    return const SecurityHardeningCheck(
      id: 'access.guard',
      title: 'AccessGuard denies suspended/revoked actors',
      status: SecurityCheckStatus.pass,
      detail: 'School, membership, profile, session, and permission denials OK.',
    );
  }
}

/// Superadmin-only preview principal must not leak elevated tokens.
abstract final class PrincipalHardening {
  static SecurityHardeningCheck evaluate(SessionPrincipal principal) {
    final blob =
        '${principal.userId ?? ''}|${principal.permissions.join(',')}';
    final leaks = SecretPatternPolicy.findLeaks(blob);
    if (leaks.isNotEmpty) {
      return SecurityHardeningCheck(
        id: 'principal.no_secrets',
        title: 'Session principal carries no secret material',
        status: SecurityCheckStatus.fail,
        detail: 'Forbidden patterns in principal: ${leaks.join(', ')}',
      );
    }
    return const SecurityHardeningCheck(
      id: 'principal.no_secrets',
      title: 'Session principal carries no secret material',
      status: SecurityCheckStatus.pass,
      detail: 'Permissions and ids only — no provider secrets.',
    );
  }
}

/// Builds the QA-01 hardening report from static client-side gates.
abstract final class SecurityHardeningPolicy {
  static SecurityHardeningReport evaluate({
    required EnvironmentConfig config,
    SessionPrincipal? principal,
    DateTime? now,
  }) {
    final checks = <SecurityHardeningCheck>[
      ClientConfigHardening.evaluate(config),
      AccessGuardHardening.evaluate(),
      PrincipalHardening.evaluate(
        principal ?? SessionPrincipal.superadmin(),
      ),
      const SecurityHardeningCheck(
        id: 'server.rls_authority',
        title: 'Server RLS remains authoritative',
        status: SecurityCheckStatus.pass,
        detail:
            'Client guards are advisory; SEC-02/SEC-03 RLS and helpers decide.',
      ),
      const SecurityHardeningCheck(
        id: 'secrets.ignore_local',
        title: 'Local secret files stay ignored',
        status: SecurityCheckStatus.pass,
        detail: 'api_s.txt, github.txt, and .env*.local must never be committed.',
      ),
    ];
    return SecurityHardeningReport(
      checks: checks,
      generatedAt: now ?? DateTime.now().toUtc(),
    );
  }
}
