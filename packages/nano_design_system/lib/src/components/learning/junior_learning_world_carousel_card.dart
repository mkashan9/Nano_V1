import 'package:flutter/material.dart';
import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Featured subject world card for the Junior Learning carousel (VIS-02).
class JuniorLearningWorldCarouselCard extends StatelessWidget {
  const JuniorLearningWorldCarouselCard({
    super.key,
    required this.title,
    required this.playLabel,
    required this.backgroundColor,
    this.filledStars = 2,
    this.illustration,
    this.onPlay,
  });

  final String title;
  final String playLabel;
  final Color backgroundColor;
  final int filledStars;
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
                  backgroundColor,
                  Color.lerp(backgroundColor, const Color(0xFF7EC8FF), 0.55)!,
                ],
              ),
            ),
            child: ClipRRect(
              borderRadius: NanoRadii.juniorCard,
              child: Stack(
                children: [
                  if (illustration != null)
                    Positioned.fill(
                      child: Image(
                        image: illustration!,
                        fit: BoxFit.cover,
                        alignment: Alignment.bottomCenter,
                      ),
                    ),
                  Padding(
                    padding: const EdgeInsets.all(NanoSpacing.md),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                              ),
                        ),
                        const SizedBox(height: NanoSpacing.xs),
                        Row(
                          children: [
                            for (var i = 0; i < 3; i++)
                              Icon(
                                Icons.star_rounded,
                                size: 20,
                                color: i < filledStars
                                    ? const Color(0xFFFFD54A)
                                    : const Color(0xFF4A3A9A),
                              ),
                          ],
                        ),
                        const Expanded(child: SizedBox.shrink()),
                        Center(
                          child: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5B3CC4),
                              visualDensity: VisualDensity.compact,
                              padding: const EdgeInsets.symmetric(
                                horizontal: NanoSpacing.lg,
                                vertical: NanoSpacing.sm,
                              ),
                              shape: const StadiumBorder(),
                            ),
                            onPressed: onPlay,
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(playLabel),
                          ),
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
