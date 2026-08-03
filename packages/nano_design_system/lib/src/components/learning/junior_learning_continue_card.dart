import 'package:flutter/material.dart';
import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// "Continue where you stopped" row for Junior Learning (VIS-02).
class JuniorLearningContinueCard extends StatelessWidget {
  const JuniorLearningContinueCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.playLabel,
    this.progress = 0.4,
    this.filledStars = 2,
    this.illustration,
    this.onPlay,
  });

  final String title;
  final String subtitle;
  final String playLabel;
  final double progress;
  final int filledStars;
  final ImageProvider? illustration;
  final VoidCallback? onPlay;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onPlay != null,
      label: '$title $subtitle',
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onPlay,
          borderRadius: NanoRadii.juniorCard,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: NanoRadii.juniorCard,
              gradient: const LinearGradient(
                begin: Alignment.centerLeft,
                end: Alignment.centerRight,
                colors: [Color(0xFF1A2458), Color(0xFF2A1A5C)],
              ),
            ),
            child: ClipRRect(
              borderRadius: NanoRadii.juniorCard,
              child: Row(
                children: [
                  SizedBox(
                    width: 96,
                    height: 112,
                    child: illustration == null
                        ? const Center(
                            child: Icon(
                              Icons.rocket_launch,
                              color: Colors.white70,
                              size: 40,
                            ),
                          )
                        : Image(image: illustration!, fit: BoxFit.cover),
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: NanoSpacing.md,
                        vertical: NanoSpacing.sm,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisAlignment: MainAxisAlignment.center,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .titleMedium
                                ?.copyWith(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                ),
                          ),
                          Text(
                            subtitle,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: Theme.of(context)
                                .textTheme
                                .bodySmall
                                ?.copyWith(color: Colors.white70),
                          ),
                          Row(
                            children: [
                              for (var i = 0; i < 3; i++)
                                Icon(
                                  Icons.star_rounded,
                                  size: 14,
                                  color: i < filledStars
                                      ? const Color(0xFFFFD54A)
                                      : const Color(0xFF4A3A9A),
                                ),
                            ],
                          ),
                          const SizedBox(height: NanoSpacing.xs),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(NanoRadii.pill),
                            child: LinearProgressIndicator(
                              value: progress.clamp(0.0, 1.0),
                              minHeight: 5,
                              backgroundColor: const Color(0xFF2A3358),
                              color: const Color(0xFF7B61FF),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(right: NanoSpacing.md),
                    child: Semantics(
                      button: true,
                      label: playLabel,
                      child: Material(
                        color: Colors.white,
                        shape: const CircleBorder(),
                        child: InkWell(
                          customBorder: const CircleBorder(),
                          onTap: onPlay,
                          child: const SizedBox(
                            width: 44,
                            height: 44,
                            child: Icon(
                              Icons.play_arrow_rounded,
                              color: Color(0xFF5B3CC4),
                            ),
                          ),
                        ),
                      ),
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
