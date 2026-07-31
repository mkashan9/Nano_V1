import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

class NanoLocaleScope extends InheritedWidget {
  const NanoLocaleScope({
    super.key,
    required this.locale,
    required this.copy,
    required super.child,
  });

  final NanoAppLocale locale;
  final NanoCopy copy;

  static NanoLocaleScope of(BuildContext context) {
    final scope =
        context.dependOnInheritedWidgetOfExactType<NanoLocaleScope>();
    assert(scope != null, 'NanoLocaleScope not found in context');
    return scope!;
  }

  static NanoLocaleScope? maybeOf(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<NanoLocaleScope>();
  }

  static NanoCopy copyOf(BuildContext context) => of(context).copy;

  static NanoAppLocale localeOf(BuildContext context) => of(context).locale;

  @override
  bool updateShouldNotify(NanoLocaleScope oldWidget) =>
      locale != oldWidget.locale;
}
