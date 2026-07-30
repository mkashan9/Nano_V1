import 'package:flutter/material.dart';
import '../tokens/nano_breakpoints.dart';

enum NanoWindowSize { phone, tablet, desktop }

class NanoResponsive {
  static NanoWindowSize windowSizeFor(double width) {
    if (width < NanoBreakpoints.tablet) return NanoWindowSize.phone;
    if (width < NanoBreakpoints.narrowWeb) return NanoWindowSize.tablet;
    return NanoWindowSize.desktop;
  }

  static int subjectColumnsFor({
    required NanoWindowSize size,
    required bool junior,
  }) {
    if (junior) {
      return switch (size) {
        NanoWindowSize.phone => 2,
        NanoWindowSize.tablet => 3,
        NanoWindowSize.desktop => 4,
      };
    }
    return switch (size) {
      NanoWindowSize.phone => 1,
      NanoWindowSize.tablet => 2,
      NanoWindowSize.desktop => 2,
    };
  }
}

typedef NanoResponsiveWidgetBuilder = Widget Function(
  BuildContext context,
  NanoWindowSize windowSize,
  BoxConstraints constraints,
);

class NanoResponsiveBuilder extends StatelessWidget {
  const NanoResponsiveBuilder({super.key, required this.builder});

  final NanoResponsiveWidgetBuilder builder;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final size = NanoResponsive.windowSizeFor(constraints.maxWidth);
        return builder(context, size, constraints);
      },
    );
  }
}

/// Constrains content for large screens while keeping phone-first layouts.
class NanoMaxContentWidth extends StatelessWidget {
  const NanoMaxContentWidth({
    super.key,
    required this.child,
    this.maxWidth = 720,
  });

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}
