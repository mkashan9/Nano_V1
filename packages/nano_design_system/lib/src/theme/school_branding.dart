import 'package:flutter/material.dart';
import '../tokens/nano_colors.dart';

/// Approved brand slots only — cannot override safety or contrast-critical colors.
class SchoolBranding {
  const SchoolBranding({
    this.primary,
    this.secondary,
    this.logoAsset,
    this.displayName,
  });

  final Color? primary;
  final Color? secondary;
  final String? logoAsset;
  final String? displayName;

  Color get safePrimary => primary ?? NanoColors.brandPrimary;
  Color get safeSecondary => secondary ?? NanoColors.brandSecondary;

  /// Safety colors always come from NanoColors.
  Color get success => NanoColors.success;
  Color get warning => NanoColors.warning;
  Color get error => NanoColors.error;
}
