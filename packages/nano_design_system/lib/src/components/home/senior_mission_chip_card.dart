import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// Compact mission tile for Senior Home "Today's Mission" (VIS-05).
class SeniorMissionChipCard extends StatelessWidget {
  const SeniorMissionChipCard({
    super.key,
    required this.kindLabel,
    required this.title,
    required this.xpLabel,
    required this.progressLabel,
    required this.accent,
    required this.icon,
    this.onTap,
  });

  final String kindLabel;
  final String title;
  final String xpLabel;
  final String progressLabel;
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
          width: 148,
          height: 156,
          child: Padding(
            padding: const EdgeInsets.all(NanoSpacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 14,
                  backgroundColor: accent.withValues(alpha: 0.2),
                  child: Icon(icon, color: accent, size: 16),
                ),
                const SizedBox(height: 6),
                Text(
                  kindLabel,
                  style: TextStyle(
                    color: accent,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 2),
                Expanded(
                  child: Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  ),
                ),
                Text(
                  xpLabel,
                  style: const TextStyle(color: Colors.white60, fontSize: 11),
                ),
                Text(
                  progressLabel,
                  style: const TextStyle(
                    color: Colors.white38,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
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
