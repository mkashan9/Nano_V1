import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

import '../l10n/nano_locale_scope.dart';
import '../tokens/nano_motion.dart';
import '../tokens/nano_radii.dart';
import '../tokens/nano_spacing.dart';
import 'companion_slot.dart';

/// Renders a resolved [CompanionReaction] inside the layout-stable
/// [CompanionSlot] (CMP-01).
///
/// The art tier decides how much movement there is; the caption is text either
/// way, so a muted or reduced-motion learner reads the same line the voice
/// would have spoken.
class CompanionStage extends StatelessWidget {
  const CompanionStage({
    super.key,
    required this.reaction,
    this.companionName,
    this.locale,
    this.size,
    this.onDismiss,
  });

  final CompanionReaction? reaction;

  /// Overrides the name the reaction already carries.
  final String? companionName;
  final NanoAppLocale? locale;

  /// Overrides the size the reaction's prominence would pick.
  final double? size;
  final VoidCallback? onDismiss;

  @override
  Widget build(BuildContext context) {
    final current = reaction;
    if (current == null) return const SizedBox.shrink();

    final theme = Theme.of(context);
    final resolvedLocale =
        locale ?? NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final name = companionName ?? current.companionName;
    final caption = current.captionFor(resolvedLocale, companionName: name);
    final artSize = size ?? (current.prominent ? 96 : 56);

    return AnimatedSwitcher(
      duration: NanoMotion.resolve(context, NanoMotion.normal),
      child: Row(
        key: ValueKey(current.assetKey + caption),
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _CompanionArt(
            reaction: current,
            size: artSize,
            companionName: name,
          ),
          if (current.showsCaption && caption.isNotEmpty) ...[
            const SizedBox(width: NanoSpacing.sm),
            Expanded(
              child: Semantics(
                liveRegion: true,
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: theme.colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(
                      current.prominent ? NanoRadii.junior : NanoRadii.senior,
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(NanoSpacing.sm),
                    child: Text(
                      caption,
                      style: current.prominent
                          ? theme.textTheme.titleMedium
                          : theme.textTheme.bodyMedium,
                    ),
                  ),
                ),
              ),
            ),
          ],
          if (onDismiss != null)
            IconButton(
              onPressed: onDismiss,
              icon: const Icon(Icons.close),
              tooltip: MaterialLocalizations.of(context).closeButtonTooltip,
            ),
        ],
      ),
    );
  }
}

class _CompanionArt extends StatelessWidget {
  const _CompanionArt({
    required this.reaction,
    required this.size,
    required this.companionName,
  });

  final CompanionReaction reaction;
  final double size;
  final String companionName;

  IconData get _moodIcon => switch (reaction.mood) {
        CompanionMood.greeting => Icons.waving_hand_rounded,
        CompanionMood.idle => Icons.pets_rounded,
        CompanionMood.point => Icons.explore_rounded,
        CompanionMood.thinking => Icons.psychology_rounded,
        CompanionMood.gentleRetry => Icons.refresh_rounded,
        CompanionMood.celebration => Icons.celebration_rounded,
      };

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    // Master art stands in for the asset ladder until MED-01 lands real files.
    // The resolved tier travels with the widget so a surface (and a golden) can
    // tell static art from a moving variant.
    return CompanionSlot(
      key: ValueKey(reaction.assetKey),
      size: size,
      semanticLabel: companionName,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
        ),
        child: Center(child: Icon(_moodIcon, size: size / 2)),
      ),
    );
  }
}
