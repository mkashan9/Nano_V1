import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

enum NanoSyncPhase { idle, syncing, failed, synced }

class NanoSyncStatusBanner extends StatelessWidget {
  const NanoSyncStatusBanner({
    super.key,
    required this.phase,
    this.message,
    this.lastUpdatedLabel,
    this.onRetry,
  });

  final NanoSyncPhase phase;
  final String? message;
  final String? lastUpdatedLabel;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    if (phase == NanoSyncPhase.idle) {
      return const SizedBox.shrink();
    }

    final (icon, color, defaultMessage) = switch (phase) {
      NanoSyncPhase.syncing => (
          Icons.sync,
          NanoColors.brandSecondary,
          'Syncing…',
        ),
      NanoSyncPhase.failed => (
          Icons.sync_problem,
          NanoColors.error,
          'Sync failed. Retry when ready.',
        ),
      NanoSyncPhase.synced => (
          Icons.cloud_done_outlined,
          NanoColors.success,
          'Up to date',
        ),
      NanoSyncPhase.idle => (
          Icons.cloud_outlined,
          NanoColors.textSecondary,
          '',
        ),
    };

    final body = [
      message ?? defaultMessage,
      if (lastUpdatedLabel != null) 'Last updated $lastUpdatedLabel',
    ].where((s) => s.isNotEmpty).join(' · ');

    return Material(
      color: color.withValues(alpha: 0.18),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NanoSpacing.md,
          vertical: NanoSpacing.sm,
        ),
        child: Row(
          children: [
            Icon(icon, color: color),
            const SizedBox(width: NanoSpacing.sm),
            Expanded(child: Text(body)),
            if (phase == NanoSyncPhase.failed && onRetry != null)
              TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}
