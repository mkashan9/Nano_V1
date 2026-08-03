import 'package:flutter/material.dart';

import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Dense senior game tile for VIS-07 grid.
class SeniorGameCard extends StatelessWidget {
  const SeniorGameCard({
    super.key,
    required this.title,
    required this.category,
    required this.xpLabel,
    required this.playLabel,
    required this.accent,
    required this.difficultyFilled,
    this.illustration,
    this.onPlay,
  });

  final String title;
  final String category;
  final String xpLabel;
  final String playLabel;
  final Color accent;
  final int difficultyFilled;
  final ImageProvider? illustration;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1D33),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: illustration == null
                    ? ColoredBox(
                        color: accent.withValues(alpha: 0.2),
                        child: Center(
                          child: Icon(Icons.sports_esports, color: accent),
                        ),
                      )
                    : Image(image: illustration!, fit: BoxFit.cover),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              category,
              style: TextStyle(
                color: accent,
                fontWeight: FontWeight.w700,
                fontSize: 11,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (var i = 0; i < 5; i++)
                  Container(
                    width: 6,
                    height: 6,
                    margin: const EdgeInsets.only(right: 3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: i < difficultyFilled
                          ? const Color(0xFF9B6DFF)
                          : const Color(0xFF3A3F5C),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    xpLabel,
                    style: const TextStyle(
                      color: Color(0xFFFF8A3D),
                      fontWeight: FontWeight.w800,
                      fontSize: 11,
                    ),
                  ),
                ),
                SizedBox(
                  height: 28,
                  child: FilledButton(
                    onPressed: onPlay,
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF9B6DFF),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      visualDensity: VisualDensity.compact,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(NanoRadii.pill),
                      ),
                    ),
                    child: Text(
                      playLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
