import '../environment/environment_config.dart';
import '../environment/nano_environment.dart';

/// QA-06 pilot release readiness checklist (aggregates QA-01..QA-05 + ops gates).

enum PilotReleaseCheckStatus { pass, warn, fail }

class PilotReleaseCheck {
  const PilotReleaseCheck({
    required this.id,
    required this.title,
    required this.status,
    required this.detail,
  });

  final String id;
  final String title;
  final PilotReleaseCheckStatus status;
  final String detail;

  bool get passed => status != PilotReleaseCheckStatus.fail;
}

class PilotReleaseReport {
  const PilotReleaseReport({
    required this.checks,
    required this.generatedAt,
  });

  final List<PilotReleaseCheck> checks;
  final DateTime generatedAt;

  bool get allPassed => checks.every((check) => check.passed);
  int get failCount =>
      checks.where((check) => check.status == PilotReleaseCheckStatus.fail).length;
}

/// Declared readiness of prior QA gates and ops drills (fake-first).
class PilotReleaseGates {
  const PilotReleaseGates({
    this.qa01Security = true,
    this.qa02Performance = true,
    this.qa03Offline = true,
    this.qa04Accessibility = true,
    this.qa05Bidi = true,
    this.featureFlagsDocumented = true,
    this.backupRestoreDocumented = true,
    this.supportScriptsReady = true,
    this.crossTenantRlsVerified = true,
    this.manualPilotScriptsListed = true,
    this.killSwitchDocumented = true,
  });

  final bool qa01Security;
  final bool qa02Performance;
  final bool qa03Offline;
  final bool qa04Accessibility;
  final bool qa05Bidi;
  final bool featureFlagsDocumented;
  final bool backupRestoreDocumented;
  final bool supportScriptsReady;
  final bool crossTenantRlsVerified;
  final bool manualPilotScriptsListed;
  final bool killSwitchDocumented;

  static const pilotReady = PilotReleaseGates();
}

abstract final class PilotReleasePolicy {
  static PilotReleaseReport evaluate({
    PilotReleaseGates gates = PilotReleaseGates.pilotReady,
    EnvironmentConfig? config,
    DateTime? now,
  }) {
    final checks = <PilotReleaseCheck>[
      _gate(
        id: 'pilot.qa01',
        title: 'QA-01 Security hardening',
        ready: gates.qa01Security,
        detailPass: 'Security checklist / anon-key gates are DONE.',
      ),
      _gate(
        id: 'pilot.qa02',
        title: 'QA-02 Performance / small device',
        ready: gates.qa02Performance,
        detailPass: '360px + text-scale smoke is DONE.',
      ),
      _gate(
        id: 'pilot.qa03',
        title: 'QA-03 Offline / poor network',
        ready: gates.qa03Offline,
        detailPass: 'Offline drafts and trusted-mutation gates are DONE.',
      ),
      _gate(
        id: 'pilot.qa04',
        title: 'QA-04 Accessibility',
        ready: gates.qa04Accessibility,
        detailPass: 'Handbook 8.5 accessibility smoke is DONE.',
      ),
      _gate(
        id: 'pilot.qa05',
        title: 'QA-05 Urdu / bidirectional',
        ready: gates.qa05Bidi,
        detailPass: 'Urdu RTL and EN LTR smoke is DONE.',
      ),
      _gate(
        id: 'pilot.feature_flags',
        title: 'Feature flags & release labels',
        ready: gates.featureFlagsDocumented,
        detailPass: 'Modules remain flaggable by school / platform (16.2).',
      ),
      _gate(
        id: 'pilot.kill_switch',
        title: 'Remote kill switch documented',
        ready: gates.killSwitchDocumented,
        detailPass: 'Games / risky integrations have a remote kill path.',
      ),
      _gate(
        id: 'pilot.rls',
        title: 'Cross-tenant RLS verified',
        ready: gates.crossTenantRlsVerified,
        detailPass: 'School A cannot read/mutate School B in RLS tests.',
      ),
      _gate(
        id: 'pilot.backup',
        title: 'Backup & restore drill',
        ready: gates.backupRestoreDocumented,
        detailPass: 'Backup/restore documented for the development project.',
      ),
      _gate(
        id: 'pilot.support',
        title: 'Support / pilot scripts',
        ready: gates.supportScriptsReady && gates.manualPilotScriptsListed,
        detailPass: 'Handbook 13.4 manual pilot scripts are listed for owners.',
      ),
      _environment(config),
    ];
    return PilotReleaseReport(
      checks: checks,
      generatedAt: now ?? DateTime.now().toUtc(),
    );
  }

  static PilotReleaseCheck _gate({
    required String id,
    required String title,
    required bool ready,
    required String detailPass,
  }) {
    return PilotReleaseCheck(
      id: id,
      title: title,
      status: ready
          ? PilotReleaseCheckStatus.pass
          : PilotReleaseCheckStatus.fail,
      detail: ready ? detailPass : '$title is not marked ready for pilot.',
    );
  }

  static PilotReleaseCheck _environment(EnvironmentConfig? config) {
    if (config == null) {
      return const PilotReleaseCheck(
        id: 'pilot.environment',
        title: 'Environment classification',
        status: PilotReleaseCheckStatus.pass,
        detail:
            'Treat remote Supabase as production until classified (ADR-0002).',
      );
    }
    final isProd = config.environment == NanoEnvironment.production;
    return PilotReleaseCheck(
      id: 'pilot.environment',
      title: 'Environment classification',
      status: isProd
          ? PilotReleaseCheckStatus.warn
          : PilotReleaseCheckStatus.pass,
      detail: isProd
          ? 'Client points at production — confirm owner approval before pilot traffic.'
          : 'Client environment is ${config.environment.name} (non-production).',
    );
  }
}
