import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// Compact recent-lesson tile for Junior Profile (VIS-04).
class JuniorRecentLearningCard extends StatelessWidget {
  const JuniorRecentLearningCard({
    super.key,
    required this.title,
    required this.subjectLabel,
    this.illustration,
    this.completed = true,
    this.onTap,
  });

  final String title;
  final String subjectLabel;
  final ImageProvider? illustration;
  final bool completed;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: onTap != null,
      label: '$title, $subjectLabel',
      child: Material(
        color: const Color(0xFF1A1D33),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: SizedBox(
            width: 132,
            child: Padding(
              padding: const EdgeInsets.all(NanoSpacing.sm),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        ClipRRect(
                          borderRadius: BorderRadius.circular(16),
                          child: illustration == null
                              ? const ColoredBox(
                                  color: Color(0xFF252845),
                                  child: Icon(
                                    Icons.menu_book,
                                    color: Colors.white54,
                                  ),
                                )
                              : Image(
                                  image: illustration!,
                                  fit: BoxFit.cover,
                                ),
                        ),
                        if (completed)
                          const Positioned(
                            top: 6,
                            right: 6,
                            child: CircleAvatar(
                              radius: 11,
                              backgroundColor: Color(0xFF2FBF71),
                              child: Icon(
                                Icons.check,
                                size: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  Text(
                    title,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(
                        Icons.star_rounded,
                        color: Color(0xFFFFD54A),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Expanded(
                        child: Text(
                          subjectLabel,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Color(0xFFB39DFF),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
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
