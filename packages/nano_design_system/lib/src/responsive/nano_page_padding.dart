import 'package:flutter/material.dart';
import '../theme/nano_theme_extension.dart';
import '../tokens/nano_breakpoints.dart';

class NanoPagePadding extends StatelessWidget {
  const NanoPagePadding({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final nano = Theme.of(context).nano;
    final width = MediaQuery.sizeOf(context).width;
    final extra = NanoBreakpoints.isDesktop(width) ? 24.0 : 0.0;
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: nano.pageGutter + extra),
      child: child,
    );
  }
}
