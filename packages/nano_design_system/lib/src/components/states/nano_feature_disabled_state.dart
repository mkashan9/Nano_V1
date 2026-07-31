import 'package:flutter/material.dart';
import '../../tokens/nano_spacing.dart';

class NanoFeatureDisabledState extends StatelessWidget {
  const NanoFeatureDisabledState({
    super.key,
    this.title = 'Not available',
    this.message = 'This feature is turned off for your school or account.',
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
            const Icon(Icons.toggle_off_outlined, size: 48),
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
