import 'package:flutter/material.dart';

import '../../tokens/nano_spacing.dart';

/// Avatar + "I'm building my future" + streak/rank + bell (VIS-05).
class SeniorHomeHeader extends StatelessWidget {
  const SeniorHomeHeader({
    super.key,
    required this.headlinePrefix,
    required this.headlineAccent,
    required this.streakDays,
    required this.streakCaption,
    required this.rankTitle,
    required this.rankLabel,
    this.avatar,
    this.hasUnread = false,
    this.onNotifications,
  });

  final String headlinePrefix;
  final String headlineAccent;
  final int streakDays;
  final String streakCaption;
  final String rankTitle;
  final String rankLabel;
  final ImageProvider? avatar;
  final bool hasUnread;
  final VoidCallback? onNotifications;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              gradient: SweepGradient(
                colors: [
                  Color(0xFF3D8BFF),
                  Color(0xFF9B6DFF),
                  Color(0xFFFF4F9A),
                  Color(0xFFFFD54A),
                  Color(0xFF3D8BFF),
                ],
              ),
            ),
            padding: const EdgeInsets.all(2.5),
            child: ClipOval(
              child: avatar == null
                  ? const ColoredBox(
                      color: Color(0xFF1A1D33),
                      child: Icon(Icons.person, color: Colors.white),
                    )
                  : Image(image: avatar!, fit: BoxFit.cover),
            ),
          ),
          const SizedBox(width: NanoSpacing.sm),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text.rich(
                  TextSpan(
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      height: 1.25,
                    ),
                    children: [
                      TextSpan(text: headlinePrefix),
                      TextSpan(
                        text: headlineAccent,
                        style: const TextStyle(
                          color: Color(0xFFB39DFF),
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const TextSpan(
                        text: ' ✦',
                        style: TextStyle(
                          color: Color(0xFFFFD54A),
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    const Icon(Icons.local_fire_department,
                        color: Color(0xFFFF8A3D), size: 16),
                    const SizedBox(width: 4),
                    Text(
                      '$streakDays',
                      style: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        streakCaption,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.workspace_premium,
                        color: Color(0xFF9B6DFF), size: 16),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        rankTitle,
                        style: const TextStyle(
                          color: Colors.white60,
                          fontSize: 11,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Flexible(
                      child: Text(
                        rankLabel,
                        style: const TextStyle(
                          color: Color(0xFFB39DFF),
                          fontWeight: FontWeight.w800,
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          if (onNotifications != null)
            IconButton(
              onPressed: onNotifications,
              tooltip: 'Notifications',
              icon: Badge(
                isLabelVisible: hasUnread,
                child: const Icon(Icons.notifications_outlined,
                    color: Colors.white70),
              ),
            ),
        ],
      ),
    );
  }
}
