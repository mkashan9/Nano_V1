import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// "Play. Learn. Build the future." header for Senior Games (VIS-07).
class SeniorGamesHeader extends StatelessWidget {
  const SeniorGamesHeader({
    super.key,
    required this.lineOne,
    required this.lineTwo,
    required this.subtitle,
    this.illustration,
    this.onGiftTap,
  });

  final String lineOne;
  final String lineTwo;
  final String subtitle;
  final ImageProvider? illustration;
  final VoidCallback? onGiftTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lineOne,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                Text(
                  lineTwo,
                  style: const TextStyle(
                    color: Color(0xFFB39DFF),
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    height: 1.15,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
          if (illustration != null)
            SizedBox(
              width: 88,
              height: 96,
              child: Image(image: illustration!, fit: BoxFit.contain),
            )
          else
            const Icon(Icons.smart_toy, color: Colors.white54, size: 56),
          if (onGiftTap != null)
            IconButton(
              onPressed: onGiftTap,
              tooltip: 'Rewards',
              icon: const Icon(Icons.card_giftcard, color: Color(0xFF9B6DFF)),
            ),
        ],
      ),
    );
  }
}
