import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// Category explore tile for Senior Learning (VIS-06).
class SeniorCategoryCard extends StatelessWidget {
  const SeniorCategoryCard({
    super.key,
    required this.title,
    required this.meta,
    required this.difficulty,
    required this.accent,
    this.illustration,
    this.fallbackIcon = Icons.category,
    this.onTap,
  });

  final String title;
  final String meta;
  final String difficulty;
  final Color accent;
  final ImageProvider? illustration;
  final IconData fallbackIcon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFF1A1D33),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.sm),
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
                          title,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          meta,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white54,
                            fontSize: 10,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(
                    width: 40,
                    height: 40,
                    child: illustration == null
                        ? Icon(fallbackIcon, color: accent)
                        : Image(image: illustration!, fit: BoxFit.contain),
                  ),
                ],
              ),
              const Spacer(),
              Text(
                difficulty,
                style: TextStyle(
                  color: accent,
                  fontWeight: FontWeight.w700,
                  fontSize: 11,
                ),
              ),
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  value: 0.35,
                  minHeight: 3,
                  backgroundColor: const Color(0xFF2A2E4A),
                  color: accent,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
