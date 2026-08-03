import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';
import '../../accessibility/nano_accessible.dart';

/// "For Parents" entry card on Junior Profile (VIS-04).
class JuniorParentsCard extends StatelessWidget {
  const JuniorParentsCard({
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
    return NanoAccessibleTarget(
      label: '$title. $subtitle',
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(NanoSpacing.md),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1D33),
          borderRadius: BorderRadius.circular(20),
        ),
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
            const SizedBox(height: NanoSpacing.md),
            const Center(
              child: CircleAvatar(
                radius: 36,
                backgroundColor: Color(0xFF3D8BFF),
                child: Icon(Icons.groups, color: Colors.white, size: 36),
              ),
            ),
            const SizedBox(height: NanoSpacing.md),
            Row(
              children: [
                Expanded(
                  child: Text(
                    subtitle,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Icon(
                  Icons.chevron_right,
                  color: Color(0xFF9B6DFF),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
