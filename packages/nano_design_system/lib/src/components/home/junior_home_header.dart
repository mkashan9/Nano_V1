import 'package:flutter/material.dart';
import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';
import '../../accessibility/nano_accessible.dart';

/// Junior home header: avatar + greeting + streak star badge (VIS-01).
class JuniorHomeHeader extends StatelessWidget {
  const JuniorHomeHeader({
    super.key,
    required this.greeting,
    required this.badgeValue,
    this.avatar,
    this.onAvatarTap,
  });

  final String greeting;
  final int badgeValue;
  final ImageProvider? avatar;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Row(
        children: [
          NanoAccessibleTarget(
            label: 'Profile avatar',
            onTap: onAvatarTap,
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: const Color(0xFF9B6DFF),
                  width: 2.5,
                ),
              ),
              child: ClipOval(
                child: avatar == null
                    ? ColoredBox(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.person),
                      )
                    : Image(image: avatar!, fit: BoxFit.cover),
              ),
            ),
          ),
          const SizedBox(width: NanoSpacing.sm),
          Expanded(
            child: Text(
              greeting,
              style: theme.textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
          Semantics(
            label: 'Streak $badgeValue',
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                borderRadius: BorderRadius.circular(NanoRadii.pill),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.star_rounded, color: Color(0xFFFFD54A), size: 20),
                  const SizedBox(width: 4),
                  Text(
                    '$badgeValue',
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
