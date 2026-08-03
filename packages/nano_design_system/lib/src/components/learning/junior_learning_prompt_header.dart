import 'package:flutter/material.dart';
import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Search + fox prompt + mic header for Junior Learning (VIS-02).
class JuniorLearningPromptHeader extends StatelessWidget {
  const JuniorLearningPromptHeader({
    super.key,
    required this.prompt,
    this.foxIllustration,
    this.onSearch,
    this.onMic,
  });

  final String prompt;
  final ImageProvider? foxIllustration;
  final VoidCallback? onSearch;
  final VoidCallback? onMic;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _RoundAction(
            icon: Icons.search,
            color: const Color(0xFF7B61FF),
            onTap: onSearch,
            semanticLabel: 'Search',
          ),
          const SizedBox(width: NanoSpacing.sm),
          Expanded(
            child: Row(
              children: [
                SizedBox(
                  width: 72,
                  height: 80,
                  child: foxIllustration == null
                      ? const Icon(Icons.pets, size: 48, color: Colors.orange)
                      : Image(image: foxIllustration!, fit: BoxFit.contain),
                ),
                const SizedBox(width: NanoSpacing.sm),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: NanoSpacing.md,
                      vertical: NanoSpacing.sm,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A1F3A),
                      borderRadius: BorderRadius.circular(NanoRadii.pill),
                    ),
                    child: Text(
                      prompt,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: Colors.white,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: NanoSpacing.sm),
          _RoundAction(
            icon: Icons.mic,
            color: const Color(0xFF3D8BFF),
            onTap: onMic,
            semanticLabel: 'Voice search',
          ),
        ],
      ),
    );
  }
}

class _RoundAction extends StatelessWidget {
  const _RoundAction({
    required this.icon,
    required this.color,
    required this.semanticLabel,
    this.onTap,
  });

  final IconData icon;
  final Color color;
  final String semanticLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: Material(
        color: color,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: Colors.white),
          ),
        ),
      ),
    );
  }
}
