import 'package:flutter/material.dart';

import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Communities title row with search + notifications (VIS-09).
class SeniorCommunitiesHeader extends StatelessWidget {
  const SeniorCommunitiesHeader({
    super.key,
    required this.title,
    required this.subtitlePrefix,
    required this.subtitleAccent,
    this.onSearch,
    this.onNotifications,
  });

  final String title;
  final String subtitlePrefix;
  final String subtitleAccent;
  final VoidCallback? onSearch;
  final VoidCallback? onNotifications;

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
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text.rich(
                  TextSpan(
                    children: [
                      TextSpan(
                        text: subtitlePrefix,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 14,
                        ),
                      ),
                      TextSpan(
                        text: subtitleAccent,
                        style: const TextStyle(
                          color: Color(0xFFB39DFF),
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          if (onSearch != null)
            IconButton(
              onPressed: onSearch,
              icon: const Icon(Icons.search, color: Colors.white54),
            ),
          if (onNotifications != null)
            IconButton(
              onPressed: onNotifications,
              icon: Badge(
                smallSize: 8,
                backgroundColor: const Color(0xFFFF4D6D),
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white54),
              ),
            ),
        ],
      ),
    );
  }
}

/// Weekly Build Challenge hero (VIS-09).
class SeniorWeeklyChallengeHero extends StatelessWidget {
  const SeniorWeeklyChallengeHero({
    super.key,
    required this.eyebrow,
    required this.headline,
    required this.headlineAccent,
    required this.body,
    required this.challenges,
    required this.ctaLabel,
    required this.timerLabel,
    required this.rewardLabel,
    required this.joinersLabel,
    this.illustration,
    this.onJoin,
  });

  final String eyebrow;
  final String headline;
  final String headlineAccent;
  final String body;
  final List<({IconData icon, String label})> challenges;
  final String ctaLabel;
  final String timerLabel;
  final String rewardLabel;
  final String joinersLabel;
  final ImageProvider? illustration;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF2A1A55), Color(0xFF15182E)],
          ),
          border: Border.all(color: const Color(0xFF6B4CFF).withValues(alpha: 0.4)),
        ),
        padding: const EdgeInsets.all(NanoSpacing.md),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        eyebrow,
                        style: const TextStyle(
                          color: Color(0xFFB39DFF),
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text.rich(
                        TextSpan(
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            height: 1.25,
                          ),
                          children: [
                            TextSpan(text: headline),
                            TextSpan(
                              text: headlineAccent,
                              style: const TextStyle(color: Color(0xFFB39DFF)),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        body,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                      ),
                      const SizedBox(height: 8),
                      for (final c in challenges)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 4),
                          child: Row(
                            children: [
                              Icon(c.icon,
                                  size: 14, color: const Color(0xFFB39DFF)),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  c.label,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 11,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 8),
                      SizedBox(
                        height: 36,
                        child: FilledButton(
                          onPressed: onJoin,
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF9B6DFF),
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius:
                                  BorderRadius.circular(NanoRadii.pill),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                ctaLabel,
                                style: const TextStyle(
                                  fontWeight: FontWeight.w800,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const CircleAvatar(
                                radius: 8,
                                backgroundColor: Colors.white,
                                child: Icon(Icons.arrow_forward,
                                    size: 10, color: Color(0xFF9B6DFF)),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: 88,
                  height: 120,
                  child: illustration == null
                      ? const Icon(Icons.groups, color: Colors.white38, size: 48)
                      : Image(image: illustration!, fit: BoxFit.contain),
                ),
              ],
            ),
            const SizedBox(height: NanoSpacing.sm),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: [
                _MetaChip(icon: Icons.schedule, label: timerLabel),
                _MetaChip(icon: Icons.emoji_events, label: rewardLabel),
                _MetaChip(icon: Icons.groups, label: joinersLabel),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 12, color: Colors.white54),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10),
        ),
      ],
    );
  }
}
