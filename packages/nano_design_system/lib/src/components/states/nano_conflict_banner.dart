import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

/// User-facing conflict chrome — avoid technical terms like "sync queue".
class NanoConflictBanner extends StatelessWidget {
  const NanoConflictBanner({
    super.key,
    required this.message,
    this.onRetry,
    this.onDiscard,
    this.onKeepServer,
  });

  final String message;
  final VoidCallback? onRetry;
  final VoidCallback? onDiscard;
  final VoidCallback? onKeepServer;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NanoColors.warning.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NanoSpacing.md,
          vertical: NanoSpacing.sm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.merge_type, color: NanoColors.warning),
                const SizedBox(width: NanoSpacing.sm),
                Expanded(
                  child: Text(
                    message,
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ),
              ],
            ),
            const SizedBox(height: NanoSpacing.sm),
            Wrap(
              spacing: NanoSpacing.sm,
              children: [
                if (onRetry != null)
                  TextButton(onPressed: onRetry, child: const Text('Try again')),
                if (onDiscard != null)
                  TextButton(onPressed: onDiscard, child: const Text('Discard')),
                if (onKeepServer != null)
                  TextButton(
                    onPressed: onKeepServer,
                    child: const Text('Keep saved version'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
