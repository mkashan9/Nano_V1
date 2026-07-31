import 'package:flutter/material.dart';
import '../theme/nano_theme_extension.dart';

/// Ensures minimum tap target from the active Nano theme.
class NanoAccessibleTarget extends StatelessWidget {
  const NanoAccessibleTarget({
    super.key,
    required this.child,
    this.label,
    this.button = true,
    this.onTap,
  });

  final Widget child;
  final String? label;
  final bool button;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final minSize = Theme.of(context).nano.minTapTarget;
    Widget content = ConstrainedBox(
      constraints: BoxConstraints(minWidth: minSize, minHeight: minSize),
      child: Center(child: child),
    );
    if (onTap != null) {
      content = InkWell(onTap: onTap, child: content);
    }
    return Semantics(
      button: button && onTap != null,
      label: label,
      child: content,
    );
  }
}
