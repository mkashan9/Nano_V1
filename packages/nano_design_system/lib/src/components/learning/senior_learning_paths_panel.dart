import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

enum SeniorPathStepState { completed, inProgress, locked }

class SeniorPathStep {
  const SeniorPathStep({
    required this.title,
    required this.statusLabel,
    required this.state,
  });

  final String title;
  final String statusLabel;
  final SeniorPathStepState state;
}

/// Learning Paths list + mountain graphic (VIS-06).
class SeniorLearningPathsPanel extends StatelessWidget {
  const SeniorLearningPathsPanel({
    super.key,
    required this.steps,
    this.illustration,
  });

  final List<SeniorPathStep> steps;
  final ImageProvider? illustration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              children: [
                for (var i = 0; i < steps.length; i++) ...[
                  if (i > 0)
                    Container(
                      margin: const EdgeInsets.only(left: 15),
                      alignment: Alignment.centerLeft,
                      height: 16,
                      width: 2,
                      color: const Color(0xFF3A3F5C),
                    ),
                  _StepRow(step: steps[i], index: i + 1),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 120,
            height: 140,
            child: illustration == null
                ? const Icon(Icons.terrain, color: Colors.white38, size: 72)
                : Image(image: illustration!, fit: BoxFit.contain),
          ),
        ],
      ),
    );
  }
}

class _StepRow extends StatelessWidget {
  const _StepRow({required this.step, required this.index});

  final SeniorPathStep step;
  final int index;

  @override
  Widget build(BuildContext context) {
    final color = switch (step.state) {
      SeniorPathStepState.completed => const Color(0xFF2FBF71),
      SeniorPathStepState.inProgress => const Color(0xFF9B6DFF),
      SeniorPathStepState.locked => Colors.white38,
    };
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: color.withValues(alpha: 0.2),
            border: Border.all(color: color, width: 2),
          ),
          child: step.state == SeniorPathStepState.completed
              ? Icon(Icons.check, color: color, size: 16)
              : step.state == SeniorPathStepState.locked
                  ? Icon(Icons.lock, color: color, size: 14)
                  : Text(
                      '$index',
                      style: TextStyle(
                        color: color,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                step.title,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
              ),
              Text(
                step.statusLabel,
                style: TextStyle(color: color, fontSize: 12),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
