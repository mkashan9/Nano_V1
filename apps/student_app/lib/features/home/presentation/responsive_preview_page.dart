import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'junior_home_foundation.dart';
import 'senior_home_foundation.dart';

/// Development preview for phone / tablet / web widths.
class ResponsivePreviewPage extends StatefulWidget {
  const ResponsivePreviewPage({super.key});

  @override
  State<ResponsivePreviewPage> createState() => _ResponsivePreviewPageState();
}

class _ResponsivePreviewPageState extends State<ResponsivePreviewPage> {
  bool senior = false;
  double previewWidth = 390;

  @override
  Widget build(BuildContext context) {
    final theme = senior ? NanoTheme.senior() : NanoTheme.junior();
    return Theme(
      data: theme,
      child: NanoScaffold(
        padBody: false,
        appBar: AppBar(
          title: const Text('Responsive preview'),
          actions: [
            Text(senior ? 'Senior' : 'Junior'),
            Switch(value: senior, onChanged: (v) => setState(() => senior = v)),
          ],
        ),
        body: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(NanoSpacing.md),
              child: Wrap(
                spacing: NanoSpacing.sm,
                children: [
                  ChoiceChip(
                    label: const Text('Phone'),
                    selected: previewWidth == 390,
                    onSelected: (_) => setState(() => previewWidth = 390),
                  ),
                  ChoiceChip(
                    label: const Text('Tablet'),
                    selected: previewWidth == 800,
                    onSelected: (_) => setState(() => previewWidth = 800),
                  ),
                  ChoiceChip(
                    label: const Text('Web'),
                    selected: previewWidth == 1100,
                    onSelected: (_) => setState(() => previewWidth = 1100),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Center(
                child: Container(
                  width: previewWidth,
                  decoration: BoxDecoration(
                    border: Border.all(color: NanoColors.textSecondary),
                    color: theme.scaffoldBackgroundColor,
                  ),
                  child: senior
                      ? const SeniorHomeFoundation()
                      : const JuniorHomeFoundation(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
