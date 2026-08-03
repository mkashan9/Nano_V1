import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// Daily build challenge card for Senior Home (VIS-05).
class SeniorChallengeCard extends StatelessWidget {
  const SeniorChallengeCard({
    super.key,
    required this.badgeLabel,
    required this.title,
    required this.body,
    required this.rewardLabel,
    this.illustration,
    this.onStart,
  });

  final String badgeLabel;
  final String title;
  final String body;
  final String rewardLabel;
  final ImageProvider? illustration;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(NanoSpacing.md),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D33),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.bolt, color: Color(0xFF2FBF71), size: 18),
                    const SizedBox(width: 6),
                    Text(
                      badgeLabel,
                      style: const TextStyle(
                        color: Color(0xFF2FBF71),
                        fontWeight: FontWeight.w800,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  body,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFD54A), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      rewardLabel,
                      style: const TextStyle(
                        color: Color(0xFFFFD54A),
                        fontWeight: FontWeight.w700,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            width: 72,
            height: 72,
            child: illustration == null
                ? const Icon(Icons.calculate, color: Colors.white54, size: 40)
                : Image(image: illustration!, fit: BoxFit.contain),
          ),
          const SizedBox(width: 8),
          Material(
            color: const Color(0xFF9B6DFF),
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onStart,
              child: const SizedBox(
                width: 40,
                height: 40,
                child: Icon(Icons.arrow_forward, color: Colors.white, size: 20),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
