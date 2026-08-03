import 'package:flutter/material.dart';

/// Compact weekly goal card for Senior Profile (VIS-08).
class SeniorWeekGoalCard extends StatelessWidget {
  const SeniorWeekGoalCard({
    super.key,
    required this.title,
    required this.body,
    required this.progressLabel,
    required this.xpLabel,
    required this.progress,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String body;
  final String progressLabel;
  final String xpLabel;
  final double progress;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1D33),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 148,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 12,
                backgroundColor: accent.withValues(alpha: 0.2),
                child: Icon(icon, color: accent, size: 14),
              ),
              const SizedBox(height: 4),
              Text(
                title,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                ),
              ),
              Text(
                body,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              Text(
                progressLabel,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const SizedBox(height: 3),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: progress.clamp(0.0, 1.0),
                  minHeight: 3,
                  backgroundColor: const Color(0xFF2A2E4A),
                  color: accent,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                xpLabel,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 10,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
