import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

class EnvironmentBadge extends StatelessWidget {
  const EnvironmentBadge({super.key, required this.environment});

  final NanoEnvironment environment;

  @override
  Widget build(BuildContext context) {
    final label = switch (environment) {
      NanoEnvironment.development => 'DEV',
      NanoEnvironment.staging => 'STG',
      NanoEnvironment.production => 'PROD',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Chip(label: Text(label), visualDensity: VisualDensity.compact),
    );
  }
}
