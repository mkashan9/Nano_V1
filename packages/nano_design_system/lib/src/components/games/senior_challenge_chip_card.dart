import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// Daily / weekly / boss challenge chip for Senior Games (VIS-07).
class SeniorChallengeChipCard extends StatelessWidget {
  const SeniorChallengeChipCard({
    super.key,
    required this.title,
    required this.body,
    required this.ctaLabel,
    required this.accent,
    required this.icon,
    this.onTap,
  });

  final String title;
  final String body;
  final String ctaLabel;
  final Color accent;
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1D33),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: SizedBox(
          width: 168,
          child: Padding(
            padding: const EdgeInsets.all(NanoSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 16,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  child: Icon(icon, color: accent, size: 18),
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  child: Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: Colors.white70, fontSize: 11),
                  ),
                ),
                Text(
                  ctaLabel,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
