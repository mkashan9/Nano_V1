import 'package:flutter/material.dart';

enum _XyloMotion { bounce, tilt, soft, none }

class _XyloMood {
  const _XyloMood({
    required this.id,
    required this.label,
    required this.asset,
    required this.eventHint,
    this.motion = _XyloMotion.bounce,
  });

  final String id;
  final String label;
  final String asset;
  final String eventHint;
  final _XyloMotion motion;
}

/// Open-eye frame of each emotion trio (blink = +1/+2).
const _appReactions = <_XyloMood>[
  _XyloMood(
    id: 'correct',
    label: 'Correct',
    asset: 'assets/xylo/faces/face_0004.png',
    eventHint: 'Correct answer → happy eyes',
  ),
  _XyloMood(
    id: 'happy',
    label: 'Happy',
    asset: 'assets/xylo/faces/face_0001.png',
    eventHint: 'Student returns · closed-eye smile',
  ),
  _XyloMood(
    id: 'confident',
    label: 'Confident',
    asset: 'assets/xylo/faces/face_0010.png',
    eventHint: 'Achievement unlocked',
  ),
  _XyloMood(
    id: 'sassy',
    label: 'Sassy',
    asset: 'assets/xylo/faces/face_0007.png',
    eventHint: 'Playful tap / cheeky hint',
    motion: _XyloMotion.tilt,
  ),
  _XyloMood(
    id: 'shocked',
    label: 'Shocked',
    asset: 'assets/xylo/faces/face_0013.png',
    eventHint: 'Surprising result',
  ),
  _XyloMood(
    id: 'cry',
    label: 'Cry',
    asset: 'assets/xylo/faces/face_0016.png',
    eventHint: 'Student struggling',
    motion: _XyloMotion.soft,
  ),
  _XyloMood(
    id: 'wrong',
    label: 'Gentle wrong',
    asset: 'assets/xylo/faces/face_0016.png',
    eventHint: 'Incorrect — soft retry (cry soft)',
    motion: _XyloMotion.soft,
  ),
  _XyloMood(
    id: 'sleep',
    label: 'Sleep / wait',
    asset: 'assets/xylo/faces/sleep.png',
    eventHint: 'Loading / idle wait',
    motion: _XyloMotion.soft,
  ),
];

enum _PlayMode { staticMood, blink, hype, walk }

/// Trial: Megupets Xylo — full-body 2D CC0 emotional mascot.
class XyloTrialPage extends StatefulWidget {
  const XyloTrialPage({super.key});

  @override
  State<XyloTrialPage> createState() => _XyloTrialPageState();
}

class _XyloTrialPageState extends State<XyloTrialPage>
    with TickerProviderStateMixin {
  late _XyloMood _current;
  _PlayMode _mode = _PlayMode.staticMood;
  late final AnimationController _motion;
  late final AnimationController _frames;

  /// Blink trio for the currently selected happy-open emotion family.
  static const _blinkBase = 4; // face_0004..0006
  int _frameIndex = 0;

  @override
  void initState() {
    super.initState();
    _current = _appReactions.first;
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
    _frames = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..addListener(() {
        if (!mounted) return;
        final len = _sequenceLength;
        if (len <= 0) return;
        final next = (_frames.value * len).floor().clamp(0, len - 1);
        if (next != _frameIndex) setState(() => _frameIndex = next);
      });
  }

  @override
  void dispose() {
    _motion.dispose();
    _frames.dispose();
    super.dispose();
  }

  int get _sequenceLength => switch (_mode) {
        _PlayMode.blink => 3,
        _PlayMode.hype => 30,
        _PlayMode.walk => 30,
        _PlayMode.staticMood => 0,
      };

  String get _displayAsset {
    switch (_mode) {
      case _PlayMode.staticMood:
        return _current.asset;
      case _PlayMode.blink:
        final n = (_blinkBase + _frameIndex).toString().padLeft(4, '0');
        return 'assets/xylo/faces/face_$n.png';
      case _PlayMode.hype:
        final n = (_frameIndex + 1).toString().padLeft(4, '0');
        return 'assets/xylo/hype/hype_$n.png';
      case _PlayMode.walk:
        final n = (_frameIndex + 1).toString().padLeft(4, '0');
        return 'assets/xylo/walk/walk_$n.png';
    }
  }

  String get _statusLabel => switch (_mode) {
        _PlayMode.staticMood => _current.label,
        _PlayMode.blink => 'Idle blink',
        _PlayMode.hype => 'Hype celebration',
        _PlayMode.walk => 'Walk cycle',
      };

  String get _statusHint => switch (_mode) {
        _PlayMode.staticMood => _current.eventHint,
        _PlayMode.blink => 'Loading / waiting · blink loop',
        _PlayMode.hype => 'Quiz completed · hyped_01 frames',
        _PlayMode.walk => 'Student returns · walk-in',
      };

  void _selectMood(_XyloMood mood) {
    _frames.stop();
    setState(() {
      _mode = _PlayMode.staticMood;
      _current = mood;
      _frameIndex = 0;
    });
    _motion
      ..duration = switch (mood.motion) {
        _XyloMotion.bounce => const Duration(milliseconds: 550),
        _XyloMotion.tilt => const Duration(milliseconds: 700),
        _XyloMotion.soft => const Duration(milliseconds: 450),
        _XyloMotion.none => const Duration(milliseconds: 200),
      }
      ..forward(from: 0);
  }

  void _play(_PlayMode mode) {
    setState(() {
      _mode = mode;
      _frameIndex = 0;
    });
    _motion.forward(from: 0);
    final ms = switch (mode) {
      _PlayMode.blink => 900,
      _PlayMode.hype => 1800,
      _PlayMode.walk => 1600,
      _PlayMode.staticMood => 550,
    };
    _frames
      ..duration = Duration(milliseconds: ms)
      ..repeat();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Xylo (Megupets)'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Full-body 2D CC0 mascot · already colored · faces + blink + hype + walk.\n'
            'Tap an app event or play an animation.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2C),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
              child: Column(
                children: [
                  SizedBox(
                    height: 280,
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (context, child) {
                        final t = Curves.easeOutBack.transform(_motion.value);
                        final soft = Curves.easeOut.transform(_motion.value);
                        final motion = _mode == _PlayMode.staticMood
                            ? _current.motion
                            : _XyloMotion.bounce;
                        return switch (motion) {
                          _XyloMotion.bounce => Transform.scale(
                              scale: 0.88 + 0.12 * t,
                              child: child,
                            ),
                          _XyloMotion.tilt => Transform.rotate(
                              angle: (1 - soft) * -0.12,
                              child: Transform.scale(
                                scale: 0.94 + 0.06 * soft,
                                child: child,
                              ),
                            ),
                          _XyloMotion.soft => Transform.translate(
                              offset: Offset(0, (1 - soft) * 12),
                              child: Opacity(
                                opacity: 0.6 + 0.4 * soft,
                                child: child,
                              ),
                            ),
                          _XyloMotion.none => child!,
                        };
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 120),
                        child: Image.asset(
                          _displayAsset,
                          key: ValueKey(_displayAsset),
                          height: 260,
                          filterQuality: FilterQuality.high,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _statusLabel,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _statusHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('Animations', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              ChoiceChip(
                label: const Text('Blink idle'),
                selected: _mode == _PlayMode.blink,
                onSelected: (_) => _play(_PlayMode.blink),
              ),
              ChoiceChip(
                label: const Text('Hype'),
                selected: _mode == _PlayMode.hype,
                onSelected: (_) => _play(_PlayMode.hype),
              ),
              ChoiceChip(
                label: const Text('Walk'),
                selected: _mode == _PlayMode.walk,
                onSelected: (_) => _play(_PlayMode.walk),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Text(
            'App event reactions',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final mood in _appReactions)
                ChoiceChip(
                  label: Text(mood.label),
                  selected:
                      _mode == _PlayMode.staticMood && _current.id == mood.id,
                  onSelected: (_) => _selectMood(mood),
                ),
            ],
          ),
          const SizedBox(height: 24),
          Text(
            'Emotion faces (open-eye)',
            style: Theme.of(context).textTheme.titleMedium,
          ),
          const SizedBox(height: 4),
          Text(
            'Each emotion also has a 3-frame blink trio in the pack.',
            style: TextStyle(color: Colors.grey.shade700),
          ),
          const SizedBox(height: 12),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 3,
            mainAxisSpacing: 8,
            crossAxisSpacing: 8,
            children: [
              for (final n in [1, 4, 7, 10, 13, 16])
                _FaceTile(
                  asset:
                      'assets/xylo/faces/face_${n.toString().padLeft(4, '0')}.png',
                  selected: _mode == _PlayMode.staticMood &&
                      _current.asset.endsWith(
                        'face_${n.toString().padLeft(4, '0')}.png',
                      ),
                  onTap: () {
                    final match = _appReactions.firstWhere(
                      (m) => m.asset.endsWith(
                        'face_${n.toString().padLeft(4, '0')}.png',
                      ),
                      orElse: () => _XyloMood(
                        id: 'face_$n',
                        label: 'Face $n',
                        asset:
                            'assets/xylo/faces/face_${n.toString().padLeft(4, '0')}.png',
                        eventHint: 'Browse expression',
                      ),
                    );
                    _selectMood(match);
                  },
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Source: Megupets · https://opengameart.org/content/xylo · CC0 '
            '(attribution optional). DEFAULT pack is already colored.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _FaceTile extends StatelessWidget {
  const _FaceTile({
    required this.asset,
    required this.selected,
    required this.onTap,
  });

  final String asset;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: selected ? const Color(0xFFE8F3EF) : const Color(0xFF1A1F2C),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(6),
          child: Image.asset(asset, fit: BoxFit.contain),
        ),
      ),
    );
  }
}
