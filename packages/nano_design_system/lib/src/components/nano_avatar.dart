import 'package:flutter/material.dart';

import '../tokens/nano_colors.dart';
import '../tokens/nano_radii.dart';

/// Initials avatar. Nano has no uploaded profile photos yet, and initials
/// avoid leaking a face into social surfaces before privacy work lands.
class NanoAvatar extends StatelessWidget {
  const NanoAvatar({
    super.key,
    required this.initials,
    this.size = 64,
    this.backgroundColor,
    this.semanticLabel,
  });

  final String initials;
  final double size;
  final Color? backgroundColor;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel,
      image: true,
      child: Container(
        width: size,
        height: size,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: backgroundColor ?? NanoColors.canvasElevated,
          borderRadius: BorderRadius.circular(NanoRadii.avatar),
        ),
        child: Text(
          initials,
          style: TextStyle(
            fontSize: size * 0.38,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}
