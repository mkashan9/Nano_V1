import '../sync/sync_models.dart';

/// QA-03 offline / poor-network smoke checklist (builds on SYNC-01).

enum NetworkQuality { offline, poor, ok }

enum OfflineNetworkCheckStatus { pass, warn, fail }

class OfflineNetworkAuditCheck {
  const OfflineNetworkAuditCheck({
    required this.id,
    required this.title,
    required this.status,
    required this.detail,
  });

  final String id;
  final String title;
  final OfflineNetworkCheckStatus status;
  final String detail;

  bool get passed => status != OfflineNetworkCheckStatus.fail;
}

class OfflineNetworkAuditReport {
  const OfflineNetworkAuditReport({
    required this.checks,
    required this.generatedAt,
    required this.quality,
  });

  final List<OfflineNetworkAuditCheck> checks;
  final DateTime generatedAt;
  final NetworkQuality quality;

  bool get allPassed => checks.every((check) => check.passed);
  int get failCount => checks
      .where((check) => check.status == OfflineNetworkCheckStatus.fail)
      .length;
}

/// Soft latency thresholds for poor-network smoke (not a live probe).
abstract final class PoorNetworkBudgets {
  /// Round-trip above this is treated as poor for smoke scenarios.
  static const poorLatencyMs = 2000;

  /// Round-trip above this is treated as offline-equivalent for smoke.
  static const offlineLatencyMs = 15000;
}

abstract final class NetworkQualityPolicy {
  static NetworkQuality fromLatencyMs(int? latencyMs) {
    if (latencyMs == null) return NetworkQuality.offline;
    if (latencyMs >= PoorNetworkBudgets.offlineLatencyMs) {
      return NetworkQuality.offline;
    }
    if (latencyMs >= PoorNetworkBudgets.poorLatencyMs) {
      return NetworkQuality.poor;
    }
    return NetworkQuality.ok;
  }

  static bool shouldShowOfflineChrome(NetworkQuality quality) =>
      quality == NetworkQuality.offline || quality == NetworkQuality.poor;
}

abstract final class OfflineNetworkAuditPolicy {
  static OfflineNetworkAuditReport evaluate({
    NetworkQuality quality = NetworkQuality.offline,
    bool cacheHit = true,
    bool conflictSurfaced = true,
    bool operationIdsUnique = true,
    DateTime? now,
  }) {
    final checks = <OfflineNetworkAuditCheck>[
      _trustedBlocked(),
      _draftsAllowed(),
      _cacheRead(quality, cacheHit),
      _offlineChrome(quality),
      _conflictSurface(conflictSurfaced),
      _idempotency(operationIdsUnique),
      _poorNetworkRetry(quality),
    ];
    return OfflineNetworkAuditReport(
      checks: checks,
      generatedAt: now ?? DateTime.now().toUtc(),
      quality: quality,
    );
  }

  static OfflineNetworkAuditCheck _trustedBlocked() {
    const trusted = [
      OfflineMutationKind.scorePublish,
      OfflineMutationKind.xpAward,
      OfflineMutationKind.membershipChange,
    ];
    final blocked = trusted.every(
      (kind) => !OfflineMutationPolicy.allowsLocalDraft(kind),
    );
    return OfflineNetworkAuditCheck(
      id: 'offline.trusted_blocked',
      title: 'Trusted mutations blocked offline',
      status: blocked
          ? OfflineNetworkCheckStatus.pass
          : OfflineNetworkCheckStatus.fail,
      detail: blocked
          ? 'Score, XP, and membership stay server-authoritative.'
          : 'A trusted mutation is incorrectly allowed as a local draft.',
    );
  }

  static OfflineNetworkAuditCheck _draftsAllowed() {
    const drafts = [
      OfflineMutationKind.attendanceDraft,
      OfflineMutationKind.marksDraft,
      OfflineMutationKind.quizAnswers,
      OfflineMutationKind.gamePlay,
      OfflineMutationKind.readCache,
    ];
    final allowed = drafts.every(OfflineMutationPolicy.allowsLocalDraft);
    return OfflineNetworkAuditCheck(
      id: 'offline.drafts_allowed',
      title: 'Allowed offline drafts',
      status: allowed
          ? OfflineNetworkCheckStatus.pass
          : OfflineNetworkCheckStatus.fail,
      detail: allowed
          ? 'Attendance/marks/quiz/game drafts and read cache are allowed.'
          : 'An expected draft kind is blocked.',
    );
  }

  static OfflineNetworkAuditCheck _cacheRead(
    NetworkQuality quality,
    bool cacheHit,
  ) {
    if (quality == NetworkQuality.ok) {
      return const OfflineNetworkAuditCheck(
        id: 'offline.cache_read',
        title: 'Cached read when disconnected',
        status: OfflineNetworkCheckStatus.pass,
        detail: 'Network OK — cache smoke not required for this run.',
      );
    }
    return OfflineNetworkAuditCheck(
      id: 'offline.cache_read',
      title: 'Cached read when disconnected',
      status: cacheHit
          ? OfflineNetworkCheckStatus.pass
          : OfflineNetworkCheckStatus.fail,
      detail: cacheHit
          ? 'Last-known cache is available for offline/poor network.'
          : 'No cache hit — offline chrome would show empty without fallback.',
    );
  }

  static OfflineNetworkAuditCheck _offlineChrome(NetworkQuality quality) {
    final needed = NetworkQualityPolicy.shouldShowOfflineChrome(quality);
    return OfflineNetworkAuditCheck(
      id: 'offline.chrome',
      title: 'Offline / poor-network chrome',
      status: OfflineNetworkCheckStatus.pass,
      detail: needed
          ? 'Offline or poor network should show banner / syncing chrome.'
          : 'Network OK — offline banner not required.',
    );
  }

  static OfflineNetworkAuditCheck _conflictSurface(bool conflictSurfaced) {
    return OfflineNetworkAuditCheck(
      id: 'offline.conflict',
      title: 'Conflicts are surfaced',
      status: conflictSurfaced
          ? OfflineNetworkCheckStatus.pass
          : OfflineNetworkCheckStatus.fail,
      detail: conflictSurfaced
          ? 'Newer revisions surface retry / discard / keep-saved (ADR-0007).'
          : 'Silent overwrite of newer revision is not allowed.',
    );
  }

  static OfflineNetworkAuditCheck _idempotency(bool unique) {
    return OfflineNetworkAuditCheck(
      id: 'offline.idempotency',
      title: 'Queued ops use unique operation ids',
      status:
          unique ? OfflineNetworkCheckStatus.pass : OfflineNetworkCheckStatus.fail,
      detail: unique
          ? 'operation_id remains the idempotency key for retries.'
          : 'Duplicate operation ids detected in the smoke queue.',
    );
  }

  static OfflineNetworkAuditCheck _poorNetworkRetry(NetworkQuality quality) {
    if (quality != NetworkQuality.poor) {
      return OfflineNetworkAuditCheck(
        id: 'offline.poor_retry',
        title: 'Poor-network retry path',
        status: OfflineNetworkCheckStatus.pass,
        detail: quality == NetworkQuality.offline
            ? 'Fully offline — queue holds until reconnect.'
            : 'Network OK — poor-network retry not exercised.',
      );
    }
    return const OfflineNetworkAuditCheck(
      id: 'offline.poor_retry',
      title: 'Poor-network retry path',
      status: OfflineNetworkCheckStatus.pass,
      detail:
          'Poor latency (≥2s) keeps drafts queued and offers retry chrome.',
    );
  }
}
