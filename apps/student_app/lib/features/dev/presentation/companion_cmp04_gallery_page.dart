import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// CMP-04 development review gallery (debug / debug_tools only).
class CompanionCmp04GalleryPage extends StatelessWidget {
  const CompanionCmp04GalleryPage({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D1A),
      appBar: AppBar(
        title: const Text('CMP-04 Companion'),
        backgroundColor: const Color(0xFF15182B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Identity',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            'version: ${CompanionIdentity.version}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'voice: ${CompanionVoiceProfile.defaultVoiceId}',
            style: const TextStyle(color: Colors.white70),
          ),
          Text(
            'Female Aoede: not default / not enabled for new companion narration.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 8),
          Text(
            'Voice sample: VOICE_GENERATION_BLOCKED until owner file is present. '
            'Gemini approximation: ${CompanionVoiceProfile.fallbackGeminiApproximation} '
            '(VOICE_APPROXIMATION_USED). '
            'Clips: companion_generated_clips='
            '${CompanionFeatureFlags.resolve(CompanionFeatureFlagKeys.generatedClips)} '
            '→ VIDEO_REVIEW_REQUIRED static fallbacks.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          Text(
            'Junior / Senior / a11y',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            'Junior: auto-speech selected events. Senior: auto-speech off. '
            'Reduced motion → static. Sound off → captions. Classroom → essential only.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          const SizedBox(height: 24),
          Text(
            'Static poses',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final mood in CompanionMood.values)
                _PoseTile(
                  label: mood.name,
                  asset: CompanionPosePack.assetFor(mood),
                ),
              _PoseTile(
                label: 'portrait',
                asset: CompanionPosePack.portraitAsset,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Tier-2 clips',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            'All six reaction videos: VIDEO_REVIEW_REQUIRED. '
            'Runtime uses static pose + local motion. Missing clip must not blank the layout.',
            style: theme.textTheme.bodySmall?.copyWith(color: Colors.white60),
          ),
          for (final id in const [
            'onboarding_greeting',
            'quiz_completion',
            'level_up',
            'long_video_refresh',
            'return_from_inactivity',
            'gentle_retry',
          ])
            ListTile(
              dense: true,
              title: Text(id, style: const TextStyle(color: Colors.white70)),
              subtitle: const Text(
                'status: VIDEO_REVIEW_REQUIRED · replay N/A',
                style: TextStyle(color: Colors.white38),
              ),
              trailing: const Icon(Icons.image_outlined, color: Colors.white38),
            ),
        ],
      ),
    );
  }
}

class _PoseTile extends StatelessWidget {
  const _PoseTile({required this.label, required this.asset});

  final String label;
  final String asset;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 120,
      child: Column(
        children: [
          AspectRatio(
            aspectRatio: 3 / 4,
            child: DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFF1A1F3A),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF3D2A6E)),
              ),
              child: Image.asset(
                asset,
                package: CompanionPosePack.package,
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const ColoredBox(
                  color: Color(0xFF2A2F4A),
                  child: Center(
                    child: Icon(Icons.person_outline, color: Colors.white54),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelSmall?.copyWith(color: Colors.white70),
          ),
        ],
      ),
    );
  }
}
