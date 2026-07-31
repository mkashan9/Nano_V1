import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// Debug-only preview of cache, pending drafts, and conflict chrome (SYNC-01).
class SyncPreviewPage extends StatefulWidget {
  const SyncPreviewPage({super.key, this.controller});

  final NanoSyncController? controller;

  @override
  State<SyncPreviewPage> createState() => _SyncPreviewPageState();
}

class _SyncPreviewPageState extends State<SyncPreviewPage> {
  late final NanoSyncController _controller;
  SyncConflict? _conflict;

  @override
  void initState() {
    super.initState();
    _controller = widget.controller ?? NanoSyncController();
    _seed();
  }

  void _seed() {
    _controller.cache.put(
      CacheEntry(
        key: 'student.home',
        payload: const {'title': 'Home', 'subjects': 4},
        updatedAt: DateTime.now().toUtc().subtract(const Duration(minutes: 2)),
        revision: 4,
      ),
    );
    _controller.enqueueDraft(
      envelope: SyncEnvelope(
        operationId: 'att-draft-demo',
        actorId: TenancyFixtures.teacherId,
        schoolId: TenancyFixtures.alphaSchoolId,
        moduleId: 'ATT',
        operationType: SyncOperationType.attendanceDraft,
        createdAt: DateTime.now().toUtc(),
        targetRevision: 1,
      ),
      kind: OfflineMutationKind.attendanceDraft,
      payload: const {'class': '5-A', 'present': 18},
    );
  }

  void _simulateConflict() {
    final item = _controller.queue.get('att-draft-demo');
    if (item == null) return;
    setState(() {
      _conflict = _controller.queue.detectConflict(item, 5);
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoCopy(NanoAppLocale.en);
    final cache = _controller.cache.get('student.home');
    final pending = _controller.queue.pending;

    return Scaffold(
      appBar: AppBar(title: const Text('Offline & drafts')),
      body: ListView(
        padding: const EdgeInsets.all(NanoSpacing.md),
        children: [
          const NanoOfflineBanner(),
          const SizedBox(height: NanoSpacing.sm),
          NanoSyncStatusBanner(
            phase: pending.isEmpty ? NanoSyncPhase.synced : NanoSyncPhase.failed,
            lastUpdatedLabel: cache?.lastUpdatedLabel,
            onRetry: pending.isEmpty ? null : _simulateConflict,
          ),
          if (_conflict != null) ...[
            const SizedBox(height: NanoSpacing.sm),
            NanoConflictBanner(
              message: copy.conflictMessage,
              onRetry: () {
                _controller.queue.resolve(
                  _conflict!.operationId,
                  ConflictResolution.retry,
                );
                setState(() => _conflict = null);
              },
              onDiscard: () {
                _controller.queue.resolve(
                  _conflict!.operationId,
                  ConflictResolution.discard,
                );
                setState(() => _conflict = null);
              },
              onKeepServer: () {
                _controller.queue.resolve(
                  _conflict!.operationId,
                  ConflictResolution.keepServer,
                );
                setState(() => _conflict = null);
              },
            ),
          ],
          const SizedBox(height: NanoSpacing.lg),
          Text('${copy.lastUpdated}: ${cache?.lastUpdatedLabel ?? '—'}'),
          Text('Cached revision: ${cache?.revision ?? '—'}'),
          const SizedBox(height: NanoSpacing.md),
          Text(copy.pendingChanges, style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NanoSpacing.sm),
          if (pending.isEmpty)
            const Text('No pending changes.')
          else
            ...pending.map(
              (item) => ListTile(
                contentPadding: EdgeInsets.zero,
                title: Text(item.envelope.operationType.name),
                subtitle: Text(
                  '${item.status.name} · retries ${item.retryCount}'
                  '${item.lastError == null ? '' : ' · ${item.lastError}'}',
                ),
              ),
            ),
          const SizedBox(height: NanoSpacing.lg),
          FilledButton(
            onPressed: _simulateConflict,
            child: const Text('Simulate newer saved version'),
          ),
        ],
      ),
    );
  }
}
