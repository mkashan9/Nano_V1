import 'package:flutter/material.dart';
import '../tokens/nano_colors.dart';
import '../tokens/nano_radii.dart';
import '../tokens/nano_spacing.dart';

class XpChip extends StatelessWidget {
  const XpChip({super.key, required this.xp, this.label = 'XP'});

  final int xp;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: '$xp $label',
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: NanoSpacing.sm,
          vertical: NanoSpacing.xs,
        ),
        decoration: BoxDecoration(
          color: NanoColors.canvasElevated,
          borderRadius: BorderRadius.circular(NanoRadii.pill),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.star_rounded, color: NanoColors.warning, size: 18),
            const SizedBox(width: NanoSpacing.xxs),
            Text(
              '$xp',
              style: Theme.of(context).textTheme.labelLarge,
            ),
          ],
        ),
      ),
    );
  }
}
