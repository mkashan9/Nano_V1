import 'package:flutter/material.dart';
import '../../theme/nano_theme_extension.dart';
import '../../tokens/nano_colors.dart';
import '../../tokens/nano_spacing.dart';

class SeniorProgressCard extends StatelessWidget {
  const SeniorProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.tag,
    this.meta,
    this.onTap,
  });

  final String title;
  final double progress;
  final String? tag;
  final String? meta;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    final clamped = progress.clamp(0.0, 1.0);
    return Semantics(
      button: onTap != null,
      label: '$title, ${(clamped * 100).round()} percent complete',
      child: Material(
        color: NanoColors.surfaceCard,
        borderRadius: BorderRadius.circular(nano.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(nano.cardRadius),
          child: Padding(
            padding: EdgeInsets.all(nano.cardPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (tag != null)
                  Text(
                    tag!,
                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                          color: NanoColors.brandPrimarySoft,
                        ),
                  ),
                const SizedBox(height: NanoSpacing.xxs),
                Text(title, style: Theme.of(context).textTheme.titleMedium),
                if (meta != null) ...[
                  const SizedBox(height: NanoSpacing.xxs),
                  Text(meta!, style: Theme.of(context).textTheme.bodyMedium),
                ],
                const SizedBox(height: NanoSpacing.sm),
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: clamped,
                    minHeight: 8,
                    backgroundColor: NanoColors.canvasElevated,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
