import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoOfflineBanner extends StatelessWidget {
  const NanoOfflineBanner({
    super.key,
    this.message = 'You are offline. Changes will sync when you reconnect.',
  });

  final String message;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: NanoColors.offline.withValues(alpha: 0.2),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: NanoSpacing.md,
          vertical: NanoSpacing.sm,
        ),
        child: Row(
          children: [
            const Icon(Icons.wifi_off, color: NanoColors.offline),
            const SizedBox(width: NanoSpacing.sm),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }
}
