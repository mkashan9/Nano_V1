import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';

class NavPlaceholderPage extends StatelessWidget {
  const NavPlaceholderPage({
    super.key,
    required this.title,
    this.subtitle = 'Foundation placeholder — content arrives in later modules.',
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    return NanoScaffold(
      padBody: true,
      body: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(title, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: NanoSpacing.sm),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
