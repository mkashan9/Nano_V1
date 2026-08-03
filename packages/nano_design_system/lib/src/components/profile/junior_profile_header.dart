import 'package:flutter/material.dart';

import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';
import '../../accessibility/nano_accessible.dart';

/// Avatar + name + level/XP + fox for Junior Profile (VIS-04).
class JuniorProfileHeader extends StatelessWidget {
  const JuniorProfileHeader({
    super.key,
    required this.displayName,
    required this.level,
    required this.xpCurrent,
    required this.xpMax,
    this.avatar,
    this.foxIllustration,
    this.onAvatarTap,
  });

  final String displayName;
  final int level;
  final int xpCurrent;
  final int xpMax;
  final ImageProvider? avatar;
  final ImageProvider? foxIllustration;
  final VoidCallback? onAvatarTap;

  @override
  Widget build(BuildContext context) {
    final fraction =
        xpMax <= 0 ? 0.0 : (xpCurrent / xpMax).clamp(0.0, 1.0);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                NanoAccessibleTarget(
                  label: 'Profile avatar',
                  onTap: onAvatarTap,
                  child: Container(
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
                ),
                const SizedBox(width: NanoSpacing.sm),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              displayName,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.star_rounded,
                            color: Color(0xFFFFD54A),
                            size: 22,
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Text(
                            'Level $level',
                            style: const TextStyle(
                              color: Color(0xFFB39DFF),
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Semantics(
                            label: 'Level badge $level',
                            child: Container(
                              width: 28,
                              height: 28,
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: const Color(0xFF7B5CFF),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '$level',
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Semantics(
                        label: 'XP $xpCurrent of $xpMax',
                        child: ClipRRect(
                          borderRadius:
                              BorderRadius.circular(NanoRadii.pill),
                          child: SizedBox(
                            height: 22,
                            child: Stack(
                              children: [
                                const ColoredBox(
                                  color: Color(0xFF1A1F3A),
                                  child: SizedBox.expand(),
                                ),
                                FractionallySizedBox(
                                  widthFactor: fraction,
                                  child: const DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: LinearGradient(
                                        colors: [
                                          Color(0xFF9B6DFF),
                                          Color(0xFF3D8BFF),
                                        ],
                                      ),
                                    ),
                                    child: SizedBox.expand(),
                                  ),
                                ),
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: Padding(
                                    padding: const EdgeInsets.only(left: 6),
                                    child: Row(
                                      children: [
                                        const Icon(
                                          Icons.star_rounded,
                                          color: Color(0xFFFFD54A),
                                          size: 16,
                                        ),
                                        const Spacer(),
                                        Padding(
                                          padding:
                                              const EdgeInsets.only(right: 10),
                                          child: Text(
                                            '$xpCurrent / $xpMax',
                                            style: const TextStyle(
                                              color: Colors.white,
                                              fontSize: 12,
                                              fontWeight: FontWeight.w700,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
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
          SizedBox(
            width: 88,
            height: 100,
            child: foxIllustration == null
                ? const Icon(Icons.pets, size: 64, color: Colors.orange)
                : Align(
                    alignment: Alignment.bottomCenter,
                    child: Image(
                      image: foxIllustration!,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                  ),
          ),
        ],
      ),
    );
  }
}
