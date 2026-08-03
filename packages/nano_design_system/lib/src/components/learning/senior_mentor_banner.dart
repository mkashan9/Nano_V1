import 'package:flutter/material.dart';

import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// AI Mentor featured banner for Senior Learning (VIS-06).
class SeniorMentorBanner extends StatelessWidget {
  const SeniorMentorBanner({
    super.key,
    required this.greeting,
    required this.titlePrefix,
    required this.titleAccent,
    required this.body,
    required this.ctaLabel,
    this.illustration,
    this.onChat,
  });

  final String greeting;
  final String titlePrefix;
  final String titleAccent;
  final String body;
  final String ctaLabel;
  final ImageProvider? illustration;
  final VoidCallback? onChat;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Container(
        padding: const EdgeInsets.all(NanoSpacing.md),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [Color(0xFF1A1240), Color(0xFF0F1630)],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    greeting,
                    style: const TextStyle(color: Colors.white70, fontSize: 13),
                  ),
                  const SizedBox(height: 4),
                  Text.rich(
                    TextSpan(
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                      ),
                      children: [
                        TextSpan(text: titlePrefix),
                        TextSpan(
                          text: titleAccent,
                          style: const TextStyle(color: Color(0xFFB39DFF)),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    body,
                    style: const TextStyle(color: Colors.white60, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: FilledButton(
                      onPressed: onChat,
                      style: FilledButton.styleFrom(
                        backgroundColor: const Color(0xFF9B6DFF),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                        visualDensity: VisualDensity.compact,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(NanoRadii.pill),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Text(
                              ctaLabel,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontWeight: FontWeight.w800),
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(Icons.arrow_circle_right, size: 18),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 4),
            SizedBox(
              width: 72,
              height: 88,
              child: illustration == null
                  ? const Icon(Icons.smart_toy, color: Colors.white54, size: 48)
                  : Image(image: illustration!, fit: BoxFit.contain),
            ),
          ],
        ),
      ),
    );
  }
}
