import 'package:nano_domain/nano_domain.dart';

/// In-memory local cache. Feature modules can swap for durable storage later.
class LocalCacheStore {
  final Map<String, CacheEntry> _entries = {};

  CacheEntry? get(String key) => _entries[key];

  /// Never silently overwrite a newer revision.
  bool put(CacheEntry entry) {
    final existing = _entries[entry.key];
    if (existing != null && existing.revision > entry.revision) {
      return false;
    }
    _entries[entry.key] = entry;
    return true;
  }

  void remove(String key) => _entries.remove(key);

  List<CacheEntry> get all => List.unmodifiable(_entries.values);

  void clear() => _entries.clear();
}

/// Draft / mutation queue with idempotent enqueue by operation_id.
class SyncQueueStore {
  final Map<String, SyncQueueItem> _items = {};

  List<SyncQueueItem> get items =>
      List.unmodifiable(_items.values.toList()..sort(_byCreated));

  List<SyncQueueItem> get pending => items
      .where(
        (i) =>
            i.status == SyncItemStatus.pending ||
            i.status == SyncItemStatus.failed ||
            i.status == SyncItemStatus.conflict,
      )
      .toList();

  /// Returns the stored item. Duplicate operation_id does not create a second row.
  SyncQueueItem enqueue(SyncQueueItem item) {
    final existing = _items[item.operationId];
    if (existing != null) {
      return existing;
    }
    _items[item.operationId] = item;
    return item;
  }

  SyncQueueItem? get(String operationId) => _items[operationId];

  void update(SyncQueueItem item) {
    if (!_items.containsKey(item.operationId)) {
      throw StateError('Unknown operation ${item.operationId}');
    }
    _items[item.operationId] = item;
  }

  SyncConflict? detectConflict(SyncQueueItem item, int serverRevision) {
    final local = item.envelope.targetRevision ?? 0;
    if (serverRevision > local) {
      final conflicted = item.copyWith(
        status: SyncItemStatus.conflict,
        serverRevision: serverRevision,
        lastError: 'Server has a newer version',
      );
      update(conflicted);
      return SyncConflict(
        operationId: item.operationId,
        message: 'Someone else already saved a newer version.',
        localRevision: local,
        serverRevision: serverRevision,
      );
    }
    return null;
  }

  void resolve(String operationId, ConflictResolution resolution) {
    final item = _items[operationId];
    if (item == null) return;
    switch (resolution) {
      case ConflictResolution.retry:
        update(
          item.copyWith(
            status: SyncItemStatus.pending,
            retryCount: item.retryCount + 1,
            lastError: null,
          ),
        );
      case ConflictResolution.discard:
        update(item.copyWith(status: SyncItemStatus.discarded));
      case ConflictResolution.keepServer:
        update(item.copyWith(status: SyncItemStatus.done, lastError: null));
    }
  }

  void markSyncing(String operationId) {
    final item = _items[operationId];
    if (item == null) return;
    update(item.copyWith(status: SyncItemStatus.syncing));
  }

  void markDone(String operationId) {
    final item = _items[operationId];
    if (item == null) return;
    update(item.copyWith(status: SyncItemStatus.done, lastError: null));
  }

  void markFailed(String operationId, String error) {
    final item = _items[operationId];
    if (item == null) return;
    update(
      item.copyWith(
        status: SyncItemStatus.failed,
        retryCount: item.retryCount + 1,
        lastError: error,
      ),
    );
  }

  void clear() => _items.clear();

  static int _byCreated(SyncQueueItem a, SyncQueueItem b) =>
      a.envelope.createdAt.compareTo(b.envelope.createdAt);
}

/// Facade used by apps / future connectivity watchers.
class NanoSyncController {
  NanoSyncController({
    LocalCacheStore? cache,
    SyncQueueStore? queue,
  })  : cache = cache ?? LocalCacheStore(),
        queue = queue ?? SyncQueueStore();

  final LocalCacheStore cache;
  final SyncQueueStore queue;

  SyncQueueItem enqueueDraft({
    required SyncEnvelope envelope,
    required OfflineMutationKind kind,
    Map<String, Object?> payload = const {},
  }) {
    if (!OfflineMutationPolicy.allowsLocalDraft(kind)) {
      throw StateError('Mutation $kind cannot be queued offline');
    }
    return queue.enqueue(
      SyncQueueItem(
        envelope: envelope,
        status: SyncItemStatus.pending,
        payload: payload,
      ),
    );
  }
}
