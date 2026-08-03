import 'package:flutter/material.dart';

/// Hex-style achievement tile for Senior Profile (VIS-08).
class SeniorAchievementHexCard extends StatelessWidget {
  const SeniorAchievementHexCard({
    super.key,
    required this.title,
    required this.levelLabel,
    required this.accent,
    required this.icon,
  });

  final String title;
  final String levelLabel;
  final Color accent;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          Icon(icon, color: accent, size: 28),
          const SizedBox(height: 6),
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 11,
            ),
          ),
          Text(
            levelLabel,
            style: TextStyle(color: accent, fontSize: 10),
          ),
        ],
      ),
    );
  }
}
