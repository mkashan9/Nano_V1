import 'package:flutter/material.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class NanoMaintenanceState extends StatelessWidget {
  const NanoMaintenanceState({
    super.key,
    this.title = 'Under maintenance',
    this.message =
        'Nano is temporarily unavailable while we finish updates. Try again soon.',
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
              Icons.construction_outlined,
              size: 48,
              color: NanoColors.warning,
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
