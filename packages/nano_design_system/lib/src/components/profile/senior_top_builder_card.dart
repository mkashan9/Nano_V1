import 'package:flutter/material.dart';

import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Peer builder card for Senior Profile Top Builders (VIS-08).
class SeniorTopBuilderCard extends StatelessWidget {
  const SeniorTopBuilderCard({
    super.key,
    required this.name,
    required this.rankLabel,
    required this.streakLabel,
    required this.ctaLabel,
    this.onTap,
  });

  final String name;
  final String rankLabel;
  final String streakLabel;
  final String ctaLabel;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1D33),
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 160,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const CircleAvatar(
                    radius: 14,
                    backgroundColor: Color(0xFF3D8BFF),
                    child: Icon(Icons.person, size: 14, color: Colors.white),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                rankLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Color(0xFFB39DFF), fontSize: 10),
              ),
              Text(
                streakLabel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(color: Colors.white54, fontSize: 10),
              ),
              const Spacer(),
              SizedBox(
                width: double.infinity,
                height: 26,
                child: FilledButton(
                  onPressed: onTap,
                  style: FilledButton.styleFrom(
                    backgroundColor: const Color(0xFF9B6DFF),
                    padding: EdgeInsets.zero,
                    visualDensity: VisualDensity.compact,
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
      ),
    );
  }
}
