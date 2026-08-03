import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// CMP-04 debug review: reaction clip ids + static poses + scene anchor sample.
class CompanionReviewPage extends StatefulWidget {
  const CompanionReviewPage({super.key});

  @override
  State<CompanionReviewPage> createState() => _CompanionReviewPageState();
}

class _CompanionReviewPageState extends State<CompanionReviewPage> {
  var _previewVisible = true;
  CompanionMood _previewMood = CompanionMood.greeting;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      backgroundColor: const Color(0xFF0B0D1A),
      appBar: AppBar(
        title: const Text('Companion review'),
        backgroundColor: const Color(0xFF15182B),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Text(
            'Flags',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          Text(
            'companion_generated_clips='
            '${CompanionFeatureFlags.resolve(CompanionFeatureFlagKeys.generatedClips)}',
            style: const TextStyle(color: Colors.white70),
          ),
          const SizedBox(height: 16),
          Text(
            'Scene anchor preview',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 200,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: const LinearGradient(
                  colors: [Color(0xFF3A2A8C), Color(0xFF2D6A4F)],
                ),
              ),
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  const Align(
                    alignment: Alignment.centerLeft,
                    child: Padding(
                      padding: EdgeInsets.all(20),
                      child: Text(
                        'Continue Learning',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                  Positioned.fill(
                    child: CompanionSceneAnchor(
                      visible: _previewVisible,
                      imageAsset: CompanionPosePack.assetFor(_previewMood),
                      caption: 'Welcome back. Ready for your next step?',
                      onDismiss: () => setState(() => _previewVisible = false),
                    ),
                  ),
                ],
              ),
            ),
          ),
          TextButton(
            onPressed: () => setState(() => _previewVisible = true),
            child: const Text('Replay entrance'),
          ),
          DropdownButton<CompanionMood>(
            value: _previewMood,
            dropdownColor: const Color(0xFF15182B),
            items: [
              for (final mood in CompanionMood.values)
                DropdownMenuItem(
                  value: mood,
                  child: Text(
                    mood.name,
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
            ],
            onChanged: (m) {
              if (m != null) setState(() => _previewMood = m);
            },
          ),
          const SizedBox(height: 24),
          Text(
            'Reaction plan clip ids',
            style: theme.textTheme.titleMedium?.copyWith(color: Colors.white),
          ),
          const SizedBox(height: 8),
          for (final id in CompanionVideoPack.clipIds)
            ListTile(
              dense: true,
              title: Text(id, style: const TextStyle(color: Colors.white70)),
              subtitle: Text(
                CompanionVideoPack.assetFor(id),
                style: const TextStyle(color: Colors.white38, fontSize: 11),
              ),
              trailing: const Icon(Icons.videocam_outlined, color: Colors.white38),
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
                alignment: Alignment.bottomCenter,
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
