import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoSuspendedState extends StatelessWidget {
  const NanoSuspendedState({
    super.key,
    this.title = 'Access paused',
    this.message = 'This account or school is temporarily suspended.',
  });

  final String title;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.pause_circle_outline,
              size: 48,
              color: NanoColors.suspended,
            ),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
