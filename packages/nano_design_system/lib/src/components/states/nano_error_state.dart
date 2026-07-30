import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoErrorState extends StatelessWidget {
  const NanoErrorState({
    super.key,
    this.title = 'Something went wrong',
    this.message = 'Please try again.',
    this.onRetry,
  });

  final String title;
  final String message;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: NanoColors.error),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
            if (onRetry != null) ...[
              const SizedBox(height: NanoSpacing.md),
              FilledButton(onPressed: onRetry, child: const Text('Try again')),
            ],
          ],
        ),
      ),
    );
  }
}
