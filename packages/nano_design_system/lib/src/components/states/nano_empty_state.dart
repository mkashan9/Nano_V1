import 'package:flutter/material.dart';
import '../../tokens/nano_spacing.dart';

class NanoEmptyState extends StatelessWidget {
  const NanoEmptyState({
    super.key,
    this.title = 'Nothing here yet',
    this.message = 'Check back soon.',
    this.action,
  });

  final String title;
  final String message;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_outlined, size: 48),
            const SizedBox(height: NanoSpacing.md),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            const SizedBox(height: NanoSpacing.xs),
            Text(message, textAlign: TextAlign.center),
            if (action != null) ...[
              const SizedBox(height: NanoSpacing.md),
              action!,
            ],
          ],
        ),
      ),
    );
  }
}
