import 'package:flutter/material.dart';
import '../../tokens/nano_radii.dart';
import '../../tokens/nano_spacing.dart';

/// Continue-learning hero card matching Junior reference (VIS-01).
class JuniorContinueHeroCard extends StatelessWidget {
  const JuniorContinueHeroCard({
    super.key,
    required this.eyebrow,
    required this.title,
    required this.startLabel,
    this.illustration,
    this.onStart,
  });

  final String eyebrow;
  final String title;
  final String startLabel;
  final ImageProvider? illustration;
  final VoidCallback? onStart;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Semantics(
      button: onStart != null,
      label: '$eyebrow $title',
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onStart,
            borderRadius: NanoRadii.juniorCard,
            child: Ink(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: NanoRadii.juniorCard,
                gradient: const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Color(0xFF3A2A8C),
                    Color(0xFF1E4A6E),
                    Color(0xFF2D6A4F),
                  ],
                ),
              ),
              child: ClipRRect(
                borderRadius: NanoRadii.juniorCard,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (illustration != null)
                      Align(
                        alignment: Alignment.centerRight,
                        child: Image(
                          image: illustration!,
                          fit: BoxFit.cover,
                          width: 220,
                          height: 200,
                        ),
                      ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 140, 20),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            eyebrow,
                            style: theme.textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.9),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.headlineSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              height: 1.1,
                            ),
                          ),
                          const Spacer(),
                          FilledButton.icon(
                            onPressed: onStart,
                            style: FilledButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF5B3CC4),
                              minimumSize: const Size(120, 48),
                              shape: const StadiumBorder(),
                            ),
                            icon: const Icon(Icons.play_arrow_rounded),
                            label: Text(
                              startLabel,
                              style: const TextStyle(fontWeight: FontWeight.w700),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
