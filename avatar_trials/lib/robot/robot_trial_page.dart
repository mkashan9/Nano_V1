import 'package:flutter/material.dart';
import 'package:flutter_3d_controller/flutter_3d_controller.dart';

/// Maps app events → Quaternius LowPoly Robot clip names (CC0).
enum RobotReaction {
  idle('Idle', 'RobotArmature|Robot_Idle'),
  wave('Wave', 'RobotArmature|Robot_Wave'),
  thumbsUp('Thumbs up', 'RobotArmature|Robot_ThumbsUp'),
  dance('Dance', 'RobotArmature|Robot_Dance'),
  yes('Yes', 'RobotArmature|Robot_Yes'),
  no('No', 'RobotArmature|Robot_No'),
  sitting('Sitting', 'RobotArmature|Robot_Sitting'),
  standing('Standing', 'RobotArmature|Robot_Standing'),
  jump('Jump', 'RobotArmature|Robot_Jump'),
  run('Run', 'RobotArmature|Robot_Running'),
  punch('Punch', 'RobotArmature|Robot_Punch'),
  walk('Walk', 'RobotArmature|Robot_Walking'),
  walkJump('Walk jump', 'RobotArmature|Robot_WalkJump'),
  death('Death', 'RobotArmature|Robot_Death');

  const RobotReaction(this.label, this.clipName);

  final String label;
  final String clipName;
}

/// Trial A: Quaternius LowPoly Robot + flutter_3d_controller.
class RobotTrialPage extends StatefulWidget {
  const RobotTrialPage({super.key});

  @override
  State<RobotTrialPage> createState() => _RobotTrialPageState();
}

class _RobotTrialPageState extends State<RobotTrialPage> {
  final Flutter3DController _controller = Flutter3DController();
  List<String> _available = const [];
  RobotReaction _current = RobotReaction.idle;
  String _status = 'Loading model…';
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _controller.onModelLoaded.addListener(_onLoadedChanged);
  }

  void _onLoadedChanged() {
    if (!mounted) return;
    final loaded = _controller.onModelLoaded.value;
    setState(() {
      _loaded = loaded;
      _status = loaded ? 'Model ready' : 'Loading model…';
    });
    if (loaded) {
      _refreshAnimations();
    }
  }

  Future<void> _refreshAnimations() async {
    try {
      final list = await _controller.getAvailableAnimations();
      if (!mounted) return;
      setState(() {
        _available = list;
        _status = list.isEmpty
            ? 'Loaded, but no animation names returned'
            : 'Loaded · ${list.length} clips';
      });
      await _play(RobotReaction.idle, loop: true);
    } catch (e) {
      if (!mounted) return;
      setState(() => _status = 'Animation list failed: $e');
    }
  }

  Future<void> _play(RobotReaction reaction, {bool loop = false}) async {
    setState(() {
      _current = reaction;
      _status = 'Playing ${reaction.label}';
    });
    // Prefer exact Quaternius clip name; fall back to first match containing token.
    var name = reaction.clipName;
    if (_available.isNotEmpty && !_available.contains(name)) {
      final token = reaction.name.toLowerCase();
      final match = _available.firstWhere(
        (a) => a.toLowerCase().contains(token) ||
            a.toLowerCase().contains(reaction.label.toLowerCase()),
        orElse: () => _available.first,
      );
      name = match;
    }
    if (loop) {
      _controller.playAnimation(animationName: name);
    } else {
      _controller.playAnimation(animationName: name, loopCount: 1);
    }
  }

  @override
  void dispose() {
    _controller.onModelLoaded.removeListener(_onLoadedChanged);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Quaternius LowPoly Robot'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: Text(
              'CC0 cute robot · 14 built-in clips · local GLB · no subscription.\n'
              'Tap a reaction (maps to quiz / lesson events).',
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey.shade700, height: 1.35),
            ),
          ),
          Text(
            _status,
            style: const TextStyle(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: DecoratedBox(
              decoration: const BoxDecoration(color: Color(0xFFE8F3EF)),
              child: Flutter3DViewer(
                controller: _controller,
                src: 'assets/quaternius/animated_robot.glb',
                progressBarColor: const Color(0xFF2F6F5E),
                enableTouch: true,
                activeGestureInterceptor: true,
                onProgress: (value) {
                  // Keep UI light — status updates on load.
                },
                onLoad: (address) {
                  setState(() => _status = 'Loaded $address');
                },
                onError: (error) {
                  setState(() => _status = 'Error: $error');
                },
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 4),
            child: Text(
              'Current: ${_current.label}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            height: 168,
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
              child: Wrap(
                spacing: 8,
                runSpacing: 8,
                alignment: WrapAlignment.center,
                children: [
                  for (final reaction in RobotReaction.values)
                    FilledButton.tonal(
                      onPressed: _loaded
                          ? () => _play(
                                reaction,
                                loop: reaction == RobotReaction.idle ||
                                    reaction == RobotReaction.sitting ||
                                    reaction == RobotReaction.standing,
                              )
                          : null,
                      child: Text(reaction.label),
                    ),
                ],
              ),
            ),
          ),
          if (_available.isNotEmpty)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text(
                'Clips from GLB: ${_available.join(', ')}',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
              ),
            ),
        ],
      ),
    );
  }
}
