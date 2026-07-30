import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:video_player/video_player.dart';

class _RobotzClip {
  const _RobotzClip({
    required this.id,
    required this.label,
    required this.asset,
    required this.eventHint,
  });

  final String id;
  final String label;
  final String asset;
  final String eventHint;
}

/// Preview clips from ThreeDee's public Gumroad covers.
/// Full pack animations (after Blender export): Shruggle, Wave, Scrolling,
/// Money Falling, Thumbs Up — not yet local until Gumroad $0 download.
const _clips = <_RobotzClip>[
  _RobotzClip(
    id: 'wave',
    label: 'Wave / greeting',
    asset: 'assets/threedee_robotz/preview1.mp4',
    eventHint: 'Student meets avatar · returns',
  ),
  _RobotzClip(
    id: 'demo_a',
    label: 'Animation demo A',
    asset: 'assets/threedee_robotz/anim_demo_a.mp4',
    eventHint: 'Likely pack motion sample',
  ),
  _RobotzClip(
    id: 'demo_b',
    label: 'Animation demo B',
    asset: 'assets/threedee_robotz/anim_demo_b.mp4',
    eventHint: 'Likely pack motion sample',
  ),
];

const _poses = <String>[
  'assets/threedee_robotz/pose_a.png',
  'assets/threedee_robotz/pose_b.png',
  'assets/threedee_robotz/pose_c.png',
];

const _namedPackAnims = <String>[
  'Shruggle',
  'Wave',
  'Scrolling',
  'Money Falling',
  'Thumbs Up',
];

/// Trial D: ThreeDee Robotz — polished cartoon companion candidate.
class ThreeDeeRobotzTrialPage extends StatefulWidget {
  const ThreeDeeRobotzTrialPage({super.key});

  @override
  State<ThreeDeeRobotzTrialPage> createState() =>
      _ThreeDeeRobotzTrialPageState();
}

class _ThreeDeeRobotzTrialPageState extends State<ThreeDeeRobotzTrialPage> {
  VideoPlayerController? _controller;
  int _clipIndex = 0;
  String _status = 'Loading preview…';

  _RobotzClip get _clip => _clips[_clipIndex];

  @override
  void initState() {
    super.initState();
    _loadClip(0);
  }

  Future<void> _loadClip(int index) async {
    final next = _clips[index];
    setState(() {
      _clipIndex = index;
      _status = 'Loading ${next.label}…';
    });

    final old = _controller;
    _controller = null;
    await old?.dispose();

    final controller = VideoPlayerController.asset(next.asset);
    try {
      await controller.initialize();
      await controller.setLooping(true);
      await controller.play();
      if (!mounted) {
        await controller.dispose();
        return;
      }
      setState(() {
        _controller = controller;
        _status = 'Playing ${next.label}';
      });
    } catch (e) {
      await controller.dispose();
      if (!mounted) return;
      setState(() => _status = 'Failed: $e');
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final player = _controller;

    return Scaffold(
      appBar: AppBar(
        title: const Text('ThreeDee Robotz'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Polished modular cartoon robot (ThreeDee) · free tier now.\n'
            'This trial uses public Gumroad preview videos/poses. Full Blender '
            'pack (5 named animations + 20 poses) needs the \$0 Gumroad download.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE8F3EF),
              borderRadius: BorderRadius.circular(24),
            ),
            child: AspectRatio(
              aspectRatio: player?.value.isInitialized == true
                  ? player!.value.aspectRatio
                  : 1,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: player?.value.isInitialized == true
                    ? VideoPlayer(player!)
                    : Center(
                        child: Image.asset(
                          'assets/threedee_robotz/hero.gif',
                          fit: BoxFit.contain,
                        ),
                      ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Text(
            _status,
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          Text(
            'App event idea: ${_clip.eventHint}',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 16),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (var i = 0; i < _clips.length; i++)
                FilledButton.tonal(
                  onPressed: () => _loadClip(i),
                  child: Text(_clips[i].label),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Named animations in the full pack',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final name in _namedPackAnims)
                Chip(
                  label: Text(name),
                  backgroundColor: const Color(0xFFE8F3EF),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            'After you grab the free Gumroad download, we can export these as '
            'GLB or transparent WebP sequences and wire a real reaction controller.',
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 24),
          Text(
            'Pose / look previews',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          SizedBox(
            height: 160,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: _poses.length,
              separatorBuilder: (_, _) => const SizedBox(width: 12),
              itemBuilder: (context, index) {
                return ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: Image.asset(
                    _poses[index],
                    width: 160,
                    height: 160,
                    fit: BoxFit.cover,
                  ),
                );
              },
            ),
          ),
          const SizedBox(height: 24),
          OutlinedButton.icon(
            onPressed: () async {
              const url = 'https://threedeeshop.gumroad.com/l/robotz';
              await Clipboard.setData(const ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text(
                      'Copied Gumroad link — open it, set price to \$0, download.',
                    ),
                  ),
                );
              }
            },
            icon: const Icon(Icons.download),
            label: const Text('Copy free Gumroad download link'),
          ),
          const SizedBox(height: 8),
          Text(
            'License: royalty-free commercial use + modification. '
            'Do not redistribute the original Blender/Figma sources. '
            'Archive notes are in trials_sources/threedee_robotz/robot_source/.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
