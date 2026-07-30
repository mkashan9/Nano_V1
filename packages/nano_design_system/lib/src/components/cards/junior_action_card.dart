import 'package:flutter/material.dart';
import '../../theme/nano_theme_extension.dart';
import '../../tokens/nano_spacing.dart';

class JuniorActionCard extends StatelessWidget {
  const JuniorActionCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.subtitle,
    this.onTap,
    this.illustration,
  });

  final String title;
  final String? subtitle;
  final Color backgroundColor;
  final VoidCallback? onTap;
  final Widget? illustration;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    return Semantics(
      button: onTap != null,
      label: title,
      child: Material(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(nano.cardRadius),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(nano.cardRadius),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: nano.minTapTarget * 2.2),
            child: Padding(
              padding: EdgeInsets.all(nano.cardPadding),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (illustration != null) ...[
                    illustration!,
                    const SizedBox(height: NanoSpacing.sm),
                  ],
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
