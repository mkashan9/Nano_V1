/// SYNC-01 domain: cache metadata, sync envelopes, queue + conflict states.

enum SyncItemStatus {
  pending,
  syncing,
  failed,
  conflict,
  done,
  discarded,
}

enum SyncOperationType {
  cacheRefresh,
  attendanceDraft,
  marksDraft,
  quizResume,
  gamePendingVerify,
  other,
}

/// Offline mutation policy — offline ≠ trusted (handbook §12 / FND-05).
enum OfflineMutationKind {
  readCache,
  attendanceDraft,
  marksDraft,
  quizAnswers,
  gamePlay,
  scorePublish,
  xpAward,
  membershipChange,
}

abstract final class OfflineMutationPolicy {
  static bool allowsLocalDraft(OfflineMutationKind kind) => switch (kind) {
        OfflineMutationKind.readCache ||
        OfflineMutationKind.attendanceDraft ||
        OfflineMutationKind.marksDraft ||
        OfflineMutationKind.quizAnswers ||
        OfflineMutationKind.gamePlay =>
          true,
        OfflineMutationKind.scorePublish ||
        OfflineMutationKind.xpAward ||
        OfflineMutationKind.membershipChange =>
          false,
      };

  static bool requiresServerConfirmation(OfflineMutationKind kind) =>
      !allowsLocalDraft(kind) ||
      kind == OfflineMutationKind.attendanceDraft ||
      kind == OfflineMutationKind.marksDraft ||
      kind == OfflineMutationKind.quizAnswers ||
      kind == OfflineMutationKind.gamePlay;
}

/// Handbook §12.2 sync envelope fields.
class SyncEnvelope {
  const SyncEnvelope({
    required this.operationId,
    required this.actorId,
    required this.schoolId,
    required this.moduleId,
    required this.operationType,
    required this.createdAt,
    this.targetRevision,
    this.schemaVersion = 1,
    this.payloadChecksum = '',
    this.clientClockSkewMs = 0,
  });

  final String operationId;
  final String actorId;
  final String schoolId;
  final String moduleId;
  final SyncOperationType operationType;
  final DateTime createdAt;
  final int? targetRevision;
  final int schemaVersion;
  final String payloadChecksum;
  final int clientClockSkewMs;
}

class SyncQueueItem {
  const SyncQueueItem({
    required this.envelope,
    required this.status,
    this.payload = const {},
    this.retryCount = 0,
    this.lastError,
    this.serverRevision,
  });

  final SyncEnvelope envelope;
  final SyncItemStatus status;
  final Map<String, Object?> payload;
  final int retryCount;
  final String? lastError;
  final int? serverRevision;

  String get operationId => envelope.operationId;

  SyncQueueItem copyWith({
    SyncItemStatus? status,
    int? retryCount,
    String? lastError,
    int? serverRevision,
    Map<String, Object?>? payload,
  }) {
    return SyncQueueItem(
      envelope: envelope,
      status: status ?? this.status,
      payload: payload ?? this.payload,
      retryCount: retryCount ?? this.retryCount,
      lastError: lastError ?? this.lastError,
      serverRevision: serverRevision ?? this.serverRevision,
    );
  }
}

class CacheEntry {
  const CacheEntry({
    required this.key,
    required this.payload,
    required this.updatedAt,
    this.revision = 0,
  });

  final String key;
  final Map<String, Object?> payload;
  final DateTime updatedAt;
  final int revision;

  String get lastUpdatedLabel {
    final age = DateTime.now().toUtc().difference(updatedAt.toUtc());
    if (age.inMinutes < 1) return 'just now';
    if (age.inHours < 1) return '${age.inMinutes} min ago';
    if (age.inDays < 1) return '${age.inHours} h ago';
    return '${age.inDays} d ago';
  }
}

enum ConflictResolution { retry, discard, keepServer }

class SyncConflict {
  const SyncConflict({
    required this.operationId,
    required this.message,
    required this.localRevision,
    required this.serverRevision,
  });

  final String operationId;
  final String message;
  final int localRevision;
  final int serverRevision;
}
