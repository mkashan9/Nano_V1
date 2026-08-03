import 'package:flutter/material.dart';
import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Fox + "Today's Adventure!" prompt for Junior Games (VIS-03).
class JuniorGamesPromptHeader extends StatelessWidget {
  const JuniorGamesPromptHeader({
    super.key,
    required this.todaysLabel,
    required this.adventureLabel,
    this.foxIllustration,
  });

  final String todaysLabel;
  final String adventureLabel;
  final ImageProvider? foxIllustration;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            height: 96,
            child: foxIllustration == null
                ? const Icon(Icons.pets, size: 64, color: Colors.orange)
                : Image(image: foxIllustration!, fit: BoxFit.contain),
          ),
          const SizedBox(width: NanoSpacing.sm),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: NanoSpacing.lg,
                vertical: NanoSpacing.md,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                borderRadius: BorderRadius.circular(NanoRadii.pill),
              ),
              child: Wrap(
                crossAxisAlignment: WrapCrossAlignment.center,
                children: [
                  Text(
                    todaysLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    adventureLabel,
                    style: const TextStyle(
                      color: Color(0xFF9B6DFF),
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Text(
                    ' ★',
                    style: TextStyle(color: Color(0xFFFFD54A), fontSize: 16),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
