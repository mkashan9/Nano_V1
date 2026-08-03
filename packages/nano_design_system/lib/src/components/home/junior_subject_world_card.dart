import 'package:flutter/material.dart';
import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Illustration-led Junior subject world card (VIS-01).
class JuniorSubjectWorldCard extends StatelessWidget {
  const JuniorSubjectWorldCard({
    super.key,
    required this.title,
    required this.backgroundColor,
    this.illustration,
    this.onTap,
  });

  final String title;
  final Color backgroundColor;
  final ImageProvider? illustration;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: onTap != null,
      label: title,
      child: Material(
        color: backgroundColor,
        borderRadius: NanoRadii.juniorCard,
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
          borderRadius: NanoRadii.juniorCard,
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (illustration != null)
                Positioned(
                  left: 0,
                  right: 0,
                  bottom: 0,
                  top: 36,
                  child: Image(
                    image: illustration!,
                    fit: BoxFit.cover,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              Positioned(
                top: NanoSpacing.md,
                left: NanoSpacing.md,
                right: NanoSpacing.md,
                child: Text(
                  title,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
