import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

SyncEnvelope _envelope(String id, {int revision = 1}) => SyncEnvelope(
      operationId: id,
      actorId: 'aaaaaaaa-aaaa-aaaa-aaaa-aaaaaaaaaaaa',
      schoolId: '11111111-1111-1111-1111-111111111111',
      moduleId: 'ATT',
      operationType: SyncOperationType.attendanceDraft,
      createdAt: DateTime.utc(2026, 7, 31, 10),
      targetRevision: revision,
    );

void main() {
  group('LocalCacheStore', () {
    test('refuses older revision overwrite', () {
      final store = LocalCacheStore();
      expect(
        store.put(
          CacheEntry(
            key: 'home',
            payload: const {'v': 2},
            updatedAt: DateTime.utc(2026, 7, 31),
            revision: 2,
          ),
        ),
        isTrue,
      );
      expect(
        store.put(
          CacheEntry(
            key: 'home',
            payload: const {'v': 1},
            updatedAt: DateTime.utc(2026, 7, 30),
            revision: 1,
          ),
        ),
        isFalse,
      );
      expect(store.get('home')!.payload['v'], 2);
    });
  });

  group('SyncQueueStore', () {
    test('enqueue is idempotent by operation_id', () {
      final queue = SyncQueueStore();
      final first = queue.enqueue(
        SyncQueueItem(envelope: _envelope('op-1'), status: SyncItemStatus.pending),
      );
      final second = queue.enqueue(
        SyncQueueItem(
          envelope: _envelope('op-1'),
          status: SyncItemStatus.pending,
          payload: const {'dup': true},
        ),
      );
      expect(identical(first, second) || first.operationId == second.operationId, isTrue);
      expect(queue.items, hasLength(1));
      expect(second.payload.containsKey('dup'), isFalse);
    });

    test('detects server-newer conflict and resolves', () {
      final queue = SyncQueueStore();
      queue.enqueue(
        SyncQueueItem(envelope: _envelope('op-2', revision: 1), status: SyncItemStatus.pending),
      );
      final conflict = queue.detectConflict(queue.get('op-2')!, 3);
      expect(conflict, isNotNull);
      expect(queue.get('op-2')!.status, SyncItemStatus.conflict);

      queue.resolve('op-2', ConflictResolution.keepServer);
      expect(queue.get('op-2')!.status, SyncItemStatus.done);
    });
  });

  group('NanoSyncController', () {
    test('rejects trusted mutations from offline queue', () {
      final controller = NanoSyncController();
      expect(
        () => controller.enqueueDraft(
          envelope: _envelope('xp-1'),
          kind: OfflineMutationKind.xpAward,
        ),
        throwsStateError,
      );
    });
  });
}
