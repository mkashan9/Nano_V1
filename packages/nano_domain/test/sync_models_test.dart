import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('OfflineMutationPolicy', () {
    test('blocks trusted mutations offline', () {
      expect(
        OfflineMutationPolicy.allowsLocalDraft(OfflineMutationKind.xpAward),
        isFalse,
      );
      expect(
        OfflineMutationPolicy.allowsLocalDraft(
          OfflineMutationKind.attendanceDraft,
        ),
        isTrue,
      );
    });
  });

  group('SyncEnvelope', () {
    test('carries idempotency key', () {
      final envelope = SyncEnvelope(
        operationId: 'op-1',
        actorId: 'actor',
        schoolId: 'school',
        moduleId: 'ATT',
        operationType: SyncOperationType.attendanceDraft,
        createdAt: DateTime.utc(2026, 7, 31),
        targetRevision: 1,
      );
      expect(envelope.operationId, 'op-1');
      expect(envelope.schemaVersion, 1);
    });
  });

  group('CacheEntry', () {
    test('formats last updated label', () {
      final entry = CacheEntry(
        key: 'home',
        payload: const {'title': 'Home'},
        updatedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 3)),
      );
      expect(entry.lastUpdatedLabel, contains('min'));
    });
  });
}
