import 'package:flutter/material.dart';
import '../../theme/nano_theme_extension.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class AdminMetricCard extends StatelessWidget {
  const AdminMetricCard({
    super.key,
    required this.label,
    required this.value,
    this.icon,
  });

  final String label;
  final String value;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    return Semantics(
      label: '$label $value',
      child: Container(
        padding: EdgeInsets.all(nano.cardPadding),
        decoration: BoxDecoration(
          color: NanoColors.adminSurface,
          borderRadius: BorderRadius.circular(nano.cardRadius),
          border: Border.all(color: NanoColors.canvasElevated),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (icon != null) Icon(icon, color: Theme.of(context).colorScheme.primary),
            const SizedBox(height: NanoSpacing.xs),
            Text(value, style: Theme.of(context).textTheme.headlineMedium),
            Text(label, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ),
      ),
    );
  }
}
