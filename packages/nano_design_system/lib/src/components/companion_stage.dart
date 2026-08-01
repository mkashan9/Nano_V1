import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';

import '../l10n/nano_locale_scope.dart';
import '../tokens/nano_motion.dart';
import '../tokens/nano_radii.dart';
import '../tokens/nano_spacing.dart';
import 'companion_mode_theme.dart';
import 'companion_slot.dart';

/// Renders a resolved [CompanionReaction] inside the layout-stable
/// [CompanionSlot] (CMP-01), in the branded frame its mode asks for (CMP-02).
///
/// The art tier decides how much movement there is; the caption is text either
/// way, so a muted or reduced-motion learner reads the same line the voice
/// would have spoken. A story-card reaction gets more room, but the same frame,
/// caption design, and emblem treatment as an inline one.
class CompanionStage extends StatelessWidget {
  const CompanionStage({
    super.key,
    required this.reaction,
    this.companionName,
    this.locale,
    this.size,
    this.placement,
    this.onDismiss,
    this.onListen,
    this.action,
  });

  final CompanionReaction? reaction;

  /// Overrides the name the reaction already carries.
  final String? companionName;
  final NanoAppLocale? locale;

  /// Overrides the size the reaction's prominence would pick.
  final double? size;

  /// Where this surface puts the companion (CMP-03). Sizing follows it, and a
  /// hidden placement renders nothing at all.
  final CompanionPlacement? placement;
  final VoidCallback? onDismiss;

  /// Play this line aloud (MED-03). Null — the ordinary state — means no recording
  /// of these exact words exists, or sound is off, and the caption is the whole
  /// experience. Nothing here ever plays on its own.
  final VoidCallback? onListen;

  /// Optional primary action for a story card ("Start", "See it", …).
  final Widget? action;

  /// Art size for this placement. Junior guidance leads; Senior stays beside
  /// content that already speaks.
  static double artSizeFor({
    required CompanionPlacement? placement,
    required bool prominent,
    required bool storyCard,
  }) {
    return switch (placement) {
      null || CompanionPlacement.inline => storyCard
          ? (prominent ? 120 : 96)
          : (prominent ? 96 : 56),
      CompanionPlacement.hero =>
        storyCard ? (prominent ? 140 : 104) : (prominent ? 120 : 96),
      CompanionPlacement.aside =>
        storyCard ? (prominent ? 96 : 72) : (prominent ? 64 : 48),
      CompanionPlacement.hidden => 0,
    };
  }

  @override
  Widget build(BuildContext context) {
    final current = reaction;
    if (current == null) return const SizedBox.shrink();
    if (placement == CompanionPlacement.hidden) return const SizedBox.shrink();

    final resolvedLocale =
        locale ?? NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(resolvedLocale);
    final name = companionName ?? current.companionName;
    final caption = current.captionFor(resolvedLocale, companionName: name);
    final storyCard =
        current.presentation == CompanionPresentation.storyCard;
    final artSize = size ??
        artSizeFor(
          placement: placement,
          prominent: current.prominent,
          storyCard: storyCard,
        );

    return AnimatedSwitcher(
      duration: NanoMotion.resolve(context, NanoMotion.normal),
      child: KeyedSubtree(
        key: ValueKey('${current.assetKey}|${current.presentation.name}|$caption'),
        child: storyCard
            ? _StoryCard(
                reaction: current,
                copy: copy,
                companionName: name,
                caption: caption,
                artSize: artSize,
                onDismiss: onDismiss,
                onListen: onListen,
                action: action,
              )
            : _InlineStage(
                reaction: current,
                copy: copy,
                companionName: name,
                caption: caption,
                artSize: artSize,
                onDismiss: onDismiss,
                onListen: onListen,
              ),
      ),
    );
  }
}

class _InlineStage extends StatelessWidget {
  const _InlineStage({
    required this.reaction,
    required this.copy,
    required this.companionName,
    required this.caption,
    required this.artSize,
    required this.onDismiss,
    required this.onListen,
  });

  final CompanionReaction reaction;
  final NanoCopy copy;
  final String companionName;
  final String caption;
  final double artSize;
  final VoidCallback? onDismiss;
  final VoidCallback? onListen;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _CompanionArt(
          reaction: reaction,
          size: artSize,
          companionName: companionName,
        ),
        if (reaction.showsCaption && caption.isNotEmpty) ...[
          const SizedBox(width: NanoSpacing.sm),
          Expanded(
            child: _CaptionBubble(
              reaction: reaction,
              copy: copy,
              companionName: companionName,
              caption: caption,
              onListen: onListen,
            ),
          ),
        ],
        if (onDismiss != null)
          IconButton(
            onPressed: onDismiss,
            icon: const Icon(Icons.close),
            tooltip: copy.companionDismissLabel,
          ),
      ],
    );
  }
}

/// A rare framed moment: onboarding, a new world, a level milestone.
class _StoryCard extends StatelessWidget {
  const _StoryCard({
    required this.reaction,
    required this.copy,
    required this.companionName,
    required this.caption,
    required this.artSize,
    required this.onDismiss,
    required this.onListen,
    required this.action,
  });

  final CompanionReaction reaction;
  final NanoCopy copy;
  final String companionName;
  final String caption;
  final double artSize;
  final VoidCallback? onDismiss;
  final VoidCallback? onListen;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = CompanionModeTheme.of(reaction.mode);
    return Semantics(
      container: true,
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(NanoRadii.sheet),
          border: Border.all(color: mode.accent, width: 2),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Row(
                children: [
                  _ModeBadge(reaction: reaction, copy: copy, name: companionName),
                  const Spacer(),
                  if (onListen != null)
                    _ListenButton(copy: copy, onListen: onListen!),
                  if (onDismiss != null)
                    IconButton(
                      onPressed: onDismiss,
                      icon: const Icon(Icons.close),
                      tooltip: copy.companionDismissLabel,
                    ),
                ],
              ),
              const SizedBox(height: NanoSpacing.sm),
              _CompanionArt(
                reaction: reaction,
                size: artSize,
                companionName: companionName,
              ),
              if (reaction.showsCaption && caption.isNotEmpty) ...[
                const SizedBox(height: NanoSpacing.md),
                Text(
                  caption,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleLarge,
                ),
              ],
              if (action != null) ...[
                const SizedBox(height: NanoSpacing.md),
                action!,
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _CaptionBubble extends StatelessWidget {
  const _CaptionBubble({
    required this.reaction,
    required this.copy,
    required this.companionName,
    required this.caption,
    this.onListen,
  });

  final CompanionReaction reaction;
  final NanoCopy copy;
  final String companionName;
  final String caption;
  final VoidCallback? onListen;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      liveRegion: true,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.secondaryContainer,
          borderRadius: BorderRadius.circular(
            reaction.prominent ? NanoRadii.junior : NanoRadii.senior,
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.sm),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  _ModeBadge(reaction: reaction, copy: copy, name: companionName),
                  if (onListen != null) ...[
                    const Spacer(),
                    _ListenButton(copy: copy, onListen: onListen!),
                  ],
                ],
              ),
              const SizedBox(height: NanoSpacing.xs),
              Text(
                caption,
                style: reaction.prominent
                    ? theme.textTheme.titleMedium
                    : theme.textTheme.bodyMedium,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hear the line (MED-03). Present only when a recording of these exact words
/// exists and sound is allowed, so it is never a control that does nothing.
class _ListenButton extends StatelessWidget {
  const _ListenButton({required this.copy, required this.onListen});

  final NanoCopy copy;
  final VoidCallback onListen;

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onListen,
      icon: const Icon(Icons.volume_up_rounded),
      iconSize: NanoSpacing.lg,
      tooltip: copy.companionListenLabel,
      // The caption is already read by a screen reader as a live region; this is
      // the control, and it says what it does rather than repeating the line.
      visualDensity: VisualDensity.compact,
    );
  }
}

/// Names which Nori is speaking, so a mode never has to be guessed from colour.
class _ModeBadge extends StatelessWidget {
  const _ModeBadge({
    required this.reaction,
    required this.copy,
    required this.name,
  });

  final CompanionReaction reaction;
  final NanoCopy copy;
  final String name;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final mode = CompanionModeTheme.of(reaction.mode);
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(mode.emblem, size: NanoSpacing.md, color: mode.accent),
        const SizedBox(width: NanoSpacing.xs),
        Text(
          copy.companionModeBadge(name, reaction.mode),
          style: theme.textTheme.labelMedium?.copyWith(color: mode.accent),
        ),
      ],
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
    final mode = CompanionModeTheme.of(reaction.mode);
    // Master art stands in for the asset ladder until MED-01 lands real files.
    // The mode ring is the shared frame every variant wears; the resolved tier
    // travels with the widget so a surface (and a golden) can tell static art
    // from a moving variant.
    return CompanionSlot(
      key: ValueKey(reaction.assetKey),
      size: size,
      semanticLabel: companionName,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: theme.colorScheme.surfaceContainerHighest,
          shape: BoxShape.circle,
          border: Border.all(color: mode.accent, width: 2),
        ),
        child: Center(child: Icon(_moodIcon, size: size / 2, color: mode.accent)),
      ),
    );
  }
}
