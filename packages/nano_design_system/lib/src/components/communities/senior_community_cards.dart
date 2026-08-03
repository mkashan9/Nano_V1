import 'package:flutter/material.dart';

import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Horizontal Find-a-Team card (VIS-09).
class SeniorTeamCard extends StatelessWidget {
  const SeniorTeamCard({
    super.key,
    required this.title,
    required this.needsLabel,
    required this.membersLabel,
    required this.ctaLabel,
    required this.accent,
    required this.icon,
    this.onJoin,
  });

  final String title;
  final String needsLabel;
  final String membersLabel;
  final String ctaLabel;
  final Color accent;
  final IconData icon;
  final VoidCallback? onJoin;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1D33),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 168,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 18,
                backgroundColor: accent.withValues(alpha: 0.2),
                child: Icon(icon, color: accent, size: 20),
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
              Text(
                needsLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: accent, fontSize: 11),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.person_outline, size: 12, color: Colors.white54),
                  const SizedBox(width: 4),
                  Text(
                    membersLabel,
                    style: const TextStyle(color: Colors.white54, fontSize: 10),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 18,
                child: Stack(
                  children: [
                    for (var i = 0; i < 3; i++)
                      Positioned(
                        left: i * 12.0,
                        child: CircleAvatar(
                          radius: 8,
                          backgroundColor: [
                            const Color(0xFF3D8BFF),
                            const Color(0xFFFF8A3D),
                            const Color(0xFF2FBF71),
                          ][i],
                        ),
                      ),
                  ],
                ),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 28,
                child: FilledButton(
                  onPressed: onJoin,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9B6DFF),
                    padding: EdgeInsets.zero,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(NanoRadii.pill),
                    ),
                  ),
                  child: Text(
                    ctaLabel,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Builder Club grid tile (VIS-09).
class SeniorClubCard extends StatelessWidget {
  const SeniorClubCard({
    super.key,
    required this.title,
    required this.membersLabel,
    required this.ctaLabel,
    required this.accent,
    required this.icon,
    this.onJoin,
  });

  final String title;
  final String membersLabel;
  final String ctaLabel;
  final Color accent;
  final IconData icon;
  final VoidCallback? onJoin;

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
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: accent, size: 20),
            ),
            const SizedBox(height: 8),
            Text(
              title,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 12,
              ),
            ),
            Text(
              membersLabel,
              style: const TextStyle(color: Colors.white54, fontSize: 10),
            ),
            const SizedBox(height: 4),
            Text(
              'Active this week',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(color: Colors.white38, fontSize: 9),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                for (final c in const [
                  Color(0xFF9B6DFF),
                  Color(0xFF3D8BFF),
                  Color(0xFF2FBF71),
                  Color(0xFFFF8A3D),
                ])
                  Container(
                    width: 5,
                    height: 5,
                    margin: const EdgeInsets.only(right: 2),
                    decoration: BoxDecoration(color: c, shape: BoxShape.circle),
                  ),
              ],
            ),
            const Spacer(),
            SizedBox(
              width: double.infinity,
              height: 26,
              child: OutlinedButton(
                onPressed: onJoin,
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFFB39DFF),
                  side: const BorderSide(color: Color(0xFF3A3F5C)),
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(NanoRadii.pill),
                  ),
                ),
                child: Text(
                  ctaLabel,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Start Your Own Project CTA band (VIS-09).
class SeniorStartProjectCard extends StatelessWidget {
  const SeniorStartProjectCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.titleAccent,
    required this.bullets,
    required this.ctaLabel,
    this.illustration,
    this.onCreate,
  });

  final String eyebrow;
  final String title;
  final String titleAccent;
  final List<({IconData icon, String label})> bullets;
  final String ctaLabel;
  final ImageProvider? illustration;
  final VoidCallback? onCreate;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D33),
          borderRadius: BorderRadius.circular(18),
        ),
        padding: const EdgeInsets.all(NanoSpacing.md),
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 96,
              child: illustration == null
                  ? const Icon(Icons.laptop_mac, color: Colors.white38, size: 48)
                  : Image(image: illustration!, fit: BoxFit.contain),
            ),
            const SizedBox(width: NanoSpacing.sm),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    eyebrow,
                    style: const TextStyle(color: Colors.white54, fontSize: 11),
                  ),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 15,
                      ),
                      children: [
                        TextSpan(text: title),
                        TextSpan(
                          text: titleAccent,
                          style: const TextStyle(color: Color(0xFFB39DFF)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (final b in bullets)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 2),
                      child: Row(
                        children: [
                          Icon(b.icon, size: 12, color: const Color(0xFFB39DFF)),
                          const SizedBox(width: 4),
                          Text(
                            b.label,
                            style: const TextStyle(
                              color: Colors.white70,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 6),
                  SizedBox(
                    width: double.infinity,
                    height: 32,
                    child: FilledButton(
                      onPressed: onCreate,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9B6DFF),
                        padding: EdgeInsets.zero,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(NanoRadii.pill),
                        ),
                      ),
                      child: Text(
                        ctaLabel,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
