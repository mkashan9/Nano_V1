import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// Full-width streak CTA for Senior Profile (VIS-08).
class SeniorStreakBanner extends StatelessWidget {
  const SeniorStreakBanner({
    super.key,
    required this.title,
    required this.subtitle,
    this.onTap,
  });

  final String title;
  final String subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Material(
        color: const Color(0xFF1A1D33),
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Padding(
            padding: const EdgeInsets.all(NanoSpacing.md),
            child: Row(
              children: [
                const Icon(Icons.local_fire_department,
                    color: Color(0xFFFF8A3D), size: 28),
                const SizedBox(width: NanoSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                        ),
                      ),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white38),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
