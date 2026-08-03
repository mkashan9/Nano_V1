import 'package:flutter/material.dart';

/// Small unlock-world tile for Senior Games (VIS-07).
class SeniorUnlockWorldCard extends StatelessWidget {
  const SeniorUnlockWorldCard({
    super.key,
    required this.label,
    required this.accent,
    this.progressLabel,
    this.locked = false,
    this.completed = false,
    this.icon = Icons.public,
  });

  final String label;
  final Color accent;
  final String? progressLabel;
  final bool locked;
  final bool completed;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 78,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D33),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: completed ? accent : const Color(0xFF2A2E4A),
        ),
      ),
      child: Column(
        children: [
          Stack(
            alignment: Alignment.topRight,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: accent.withValues(alpha: 0.2),
                child: Icon(
                  locked ? Icons.lock : icon,
                  color: locked ? Colors.white38 : accent,
                  size: 18,
                ),
              ),
              if (completed)
                const Icon(Icons.check_circle, color: Color(0xFF2FBF71), size: 14),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 10,
              fontWeight: FontWeight.w700,
            ),
          ),
          if (progressLabel != null)
            Text(
              progressLabel!,
              style: TextStyle(color: accent, fontSize: 10),
            ),
        ],
      ),
    );
  }
}
