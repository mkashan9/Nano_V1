import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';
import 'nano_feedback.dart';

class NanoAccessibilityScope extends InheritedWidget {
  const NanoAccessibilityScope({
    super.key,
    required this.preferences,
    required this.feedback,
    required super.child,
  });

  final AccessibilityPreferences preferences;
  final NanoFeedback feedback;

  static NanoAccessibilityScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NanoAccessibilityScope>();
    assert(scope != null, 'NanoAccessibilityScope not found');
    return scope!;
  }

  static NanoAccessibilityScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NanoAccessibilityScope>();
  }

  @override
  bool updateShouldNotify(NanoAccessibilityScope oldWidget) =>
      preferences != oldWidget.preferences || feedback != oldWidget.feedback;
}
