import 'package:flutter/material.dart';
import '../tokens/nano_spacing.dart';

/// Layout-stable companion slot — static, animated, clip, or empty.
class CompanionSlot extends StatelessWidget {
  const CompanionSlot({
    super.key,
    this.child,
    this.size = 96,
    this.semanticLabel = 'Learning guide',
  });

  final Widget? child;
  final double size;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      child: SizedBox(
        width: size,
        height: size,
        child: child ??
            DecoratedBox(
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.pets_rounded, size: NanoSpacing.xl),
            ),
      ),
    );
  }
}
