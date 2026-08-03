import 'package:flutter/material.dart';
import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// World-style game tile for Junior Games 2×2 grid (VIS-03).
class JuniorGameWorldCard extends StatelessWidget {
  const JuniorGameWorldCard({
    super.key,
    required this.title,
    required this.playLabel,
    required this.badgeColor,
    this.illustration,
    this.onPlay,
  });

  final String title;
  final String playLabel;
  final Color badgeColor;
  final ImageProvider? illustration;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onPlay != null,
      label: '$title, $playLabel',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          borderRadius: NanoRadii.juniorCard,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: NanoRadii.juniorCard,
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Color.lerp(badgeColor, const Color(0xFF0A0C1C), 0.35)!,
                  badgeColor.withValues(alpha: 0.85),
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: NanoRadii.juniorCard,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (illustration != null)
                    Image(
                      image: illustration!,
                      fit: BoxFit.cover,
                      alignment: Alignment.center,
                    ),
                  Padding(
                    padding: const EdgeInsets.all(NanoSpacing.sm),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: NanoSpacing.md,
                            vertical: NanoSpacing.xs,
                          ),
                          decoration: BoxDecoration(
                            color: badgeColor,
                            borderRadius:
                                BorderRadius.circular(NanoRadii.pill),
                          ),
                          child: Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        const Spacer(),
                        FilledButton.icon(
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFF5B3CC4),
                            visualDensity: VisualDensity.compact,
                            padding: const EdgeInsets.symmetric(
                              horizontal: NanoSpacing.md,
                              vertical: NanoSpacing.xs,
                            ),
                            shape: const StadiumBorder(),
                          ),
                          onPressed: onPlay,
                          icon: const Icon(Icons.play_arrow_rounded, size: 20),
                          label: Text(playLabel),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
