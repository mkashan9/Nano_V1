import 'package:flutter/material.dart';

class NanoEnvironmentBadge extends StatelessWidget {
  const NanoEnvironmentBadge({super.key, required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(label),
      visualDensity: VisualDensity.compact,
    );
  }
}
