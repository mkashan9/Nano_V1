import 'package:flutter/material.dart';

import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Senior Profile identity header (VIS-08).
class SeniorProfileHeader extends StatelessWidget {
  const SeniorProfileHeader({
    super.key,
    required this.greeting,
    required this.subtitle,
    required this.rankLabel,
    required this.levelLabel,
    required this.xpLabel,
    required this.xpProgress,
    this.avatar,
    this.friendsOverflowLabel = '+3',
    this.onNotifications,
    this.onSettings,
  });

  final String greeting;
  final String subtitle;
  final String rankLabel;
  final String levelLabel;
  final String xpLabel;
  final double xpProgress;
  final ImageProvider? avatar;
  final String friendsOverflowLabel;
  final VoidCallback? onNotifications;
  final VoidCallback? onSettings;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                children: [
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF9B6DFF),
                        width: 3,
                      ),
                    ),
                    child: ClipOval(
                      child: avatar == null
                          ? const ColoredBox(
                              color: Color(0xFF1A1D33),
                              child: Icon(Icons.person, color: Colors.white),
                            )
                          : Image(image: avatar!, fit: BoxFit.cover),
                    ),
                  ),
                  Positioned(
                    right: 0,
                    bottom: 0,
                    child: Container(
                      width: 22,
                      height: 22,
                      decoration: const BoxDecoration(
                        color: Color(0xFF9B6DFF),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.edit, size: 12, color: Colors.white),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: NanoSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      greeting,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.white60, fontSize: 12),
                    ),
                  ],
                ),
              ),
              if (onNotifications != null)
                IconButton(
                  onPressed: onNotifications,
                  icon: const Icon(Icons.notifications_outlined,
                      color: Colors.white54),
                ),
              if (onSettings != null)
                IconButton(
                  onPressed: onSettings,
                  icon: const Icon(Icons.settings_outlined,
                      color: Colors.white54),
                ),
            ],
          ),
          const SizedBox(height: NanoSpacing.sm),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                flex: 3,
                child: _BadgeCard(
                  icon: Icons.workspace_premium,
                  title: 'Builder Rank',
                  value: rankLabel,
                ),
              ),
              const SizedBox(width: NanoSpacing.sm),
              Expanded(
                flex: 4,
                child: _BadgeCard(
                  icon: Icons.bar_chart,
                  title: levelLabel,
                  value: xpLabel,
                  progress: xpProgress,
                ),
              ),
              const SizedBox(width: NanoSpacing.sm),
              _FriendsStack(overflowLabel: friendsOverflowLabel),
            ],
          ),
        ],
      ),
    );
  }
}

class _BadgeCard extends StatelessWidget {
  const _BadgeCard({
    required this.icon,
    required this.title,
    required this.value,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String value;
  final double? progress;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1D33),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF9B6DFF), size: 16),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: Colors.white70, fontSize: 11),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 13,
            ),
          ),
          if (progress != null) ...[
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(NanoRadii.pill),
              child: LinearProgressIndicator(
                value: progress!.clamp(0.0, 1.0),
                minHeight: 4,
                backgroundColor: const Color(0xFF2A2E4A),
                color: const Color(0xFF9B6DFF),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _FriendsStack extends StatelessWidget {
  const _FriendsStack({required this.overflowLabel});

  final String overflowLabel;

  static const _colors = <Color>[
    Color(0xFF3D8BFF),
    Color(0xFFFF8A3D),
    Color(0xFF2FBF71),
    Color(0xFF9B6DFF),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: 72,
          height: 28,
          child: Stack(
            children: [
              for (var i = 0; i < _colors.length; i++)
                Positioned(
                  left: i * 12.0,
                  child: CircleAvatar(
                    radius: 12,
                    backgroundColor: _colors[i],
                    child: const Icon(Icons.person, size: 12, color: Colors.white),
                  ),
                ),
              Positioned(
                right: 0,
                child: CircleAvatar(
                  radius: 12,
                  backgroundColor: const Color(0xFF2A2E4A),
                  child: Text(
                    overflowLabel,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 4),
        const Text(
          'Friends',
          style: TextStyle(color: Colors.white54, fontSize: 10),
        ),
      ],
    );
  }
}
