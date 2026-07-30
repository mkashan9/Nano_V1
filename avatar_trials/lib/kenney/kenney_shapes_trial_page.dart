import 'package:flutter/material.dart';

enum _ShapeMotion { bounce, tilt, soft, clap }

class _ShapeMood {
  const _ShapeMood({
    required this.id,
    required this.label,
    required this.face,
    required this.eventHint,
    this.leftHand = 'open',
    this.rightHand = 'open',
    this.motion = _ShapeMotion.bounce,
  });

  final String id;
  final String label;
  final String face; // a-l
  final String eventHint;
  final String leftHand;
  final String rightHand;
  final _ShapeMotion motion;
}

const _reactions = <_ShapeMood>[
  _ShapeMood(
    id: 'correct',
    label: 'Correct',
    face: 'a',
    eventHint: 'Correct answer · smile + pop',
    leftHand: 'thumb',
    rightHand: 'thumb',
  ),
  _ShapeMood(
    id: 'celebrate',
    label: 'Celebrate',
    face: 'c',
    eventHint: 'Quiz done · closed-eye happy',
    leftHand: 'peace',
    rightHand: 'peace',
    motion: _ShapeMotion.clap,
  ),
  _ShapeMood(
    id: 'happy',
    label: 'Happy',
    face: 'a',
    eventHint: 'Student returns',
    leftHand: 'open',
    rightHand: 'open',
  ),
  _ShapeMood(
    id: 'thinking',
    label: 'Thinking',
    face: 'd',
    eventHint: 'Waiting for answer',
    leftHand: 'point',
    rightHand: 'closed',
    motion: _ShapeMotion.tilt,
  ),
  _ShapeMood(
    id: 'focused',
    label: 'Focused',
    face: 'f',
    eventHint: 'Lesson begins',
    leftHand: 'closed',
    rightHand: 'closed',
    motion: _ShapeMotion.tilt,
  ),
  _ShapeMood(
    id: 'confused',
    label: 'Confused',
    face: 'h',
    eventHint: 'Hint / unexpected',
    leftHand: 'open',
    rightHand: 'point',
    motion: _ShapeMotion.tilt,
  ),
  _ShapeMood(
    id: 'sad',
    label: 'Sad',
    face: 'k',
    eventHint: 'Incorrect — gentle retry',
    leftHand: 'closed',
    rightHand: 'closed',
    motion: _ShapeMotion.soft,
  ),
  _ShapeMood(
    id: 'worried',
    label: 'Worried',
    face: 'i',
    eventHint: 'Student struggling',
    leftHand: 'open',
    rightHand: 'open',
    motion: _ShapeMotion.soft,
  ),
  _ShapeMood(
    id: 'no',
    label: 'No',
    face: 'g',
    eventHint: 'Wrong (firmer)',
    leftHand: 'rock',
    rightHand: 'rock',
    motion: _ShapeMotion.soft,
  ),
  _ShapeMood(
    id: 'offline',
    label: 'Offline',
    face: 'j',
    eventHint: 'Offline / KO',
    leftHand: 'closed',
    rightHand: 'closed',
    motion: _ShapeMotion.soft,
  ),
  _ShapeMood(
    id: 'idle',
    label: 'Idle',
    face: 'b',
    eventHint: 'Loading / waiting',
    leftHand: 'open',
    rightHand: 'open',
    motion: _ShapeMotion.soft,
  ),
  _ShapeMood(
    id: 'sleep',
    label: 'Sleep',
    face: 'l',
    eventHint: 'Inactivity',
    leftHand: 'closed',
    rightHand: 'closed',
    motion: _ShapeMotion.soft,
  ),
];

const _colors = ['yellow', 'purple', 'blue', 'green', 'pink', 'red'];
const _shapes = ['squircle', 'circle'];

/// Trial 1 (simple 2D): Kenney Shape Characters — modular body/face/hands + Flutter motion.
class KenneyShapesTrialPage extends StatefulWidget {
  const KenneyShapesTrialPage({super.key});

  @override
  State<KenneyShapesTrialPage> createState() => _KenneyShapesTrialPageState();
}

class _KenneyShapesTrialPageState extends State<KenneyShapesTrialPage>
    with SingleTickerProviderStateMixin {
  late _ShapeMood _current;
  late final AnimationController _motion;
  String _color = 'yellow';
  String _shape = 'squircle';

  @override
  void initState() {
    super.initState();
    _current = _reactions.first;
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 550),
    )..forward();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  String get _bodyAsset =>
      'assets/kenney_shapes/bodies/${_color}_$_shape.png';

  String _handAsset(String pose) {
    // Yellow pack uses hand_yellow_*.png; others use {color}_hand_*.png
    if (_color == 'yellow') {
      return 'assets/kenney_shapes/hands/hand_yellow_$pose.png';
    }
    return 'assets/kenney_shapes/hands/${_color}_hand_$pose.png';
  }

  void _select(_ShapeMood mood) {
    setState(() => _current = mood);
    _motion
      ..duration = switch (mood.motion) {
        _ShapeMotion.bounce => const Duration(milliseconds: 550),
        _ShapeMotion.tilt => const Duration(milliseconds: 700),
        _ShapeMotion.soft => const Duration(milliseconds: 450),
        _ShapeMotion.clap => const Duration(milliseconds: 650),
      }
      ..forward(from: 0);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Kenney Shape Characters'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'CC0 modular mascot kit · body + face + hands · Flutter motion.\n'
            'Pick a body colour/shape, then tap an app event.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 12),
          Text('Body colour', style: Theme.of(context).textTheme.titleSmall),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final c in _colors)
                ChoiceChip(
                  label: Text(c),
                  selected: _color == c,
                  onSelected: (_) => setState(() => _color = c),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            children: [
              for (final s in _shapes)
                ChoiceChip(
                  label: Text(s),
                  selected: _shape == s,
                  onSelected: (_) => setState(() => _shape = s),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFF1A1F2C),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 28, horizontal: 12),
              child: Column(
                children: [
                  SizedBox(
                    height: 260,
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (context, child) {
                        final t = Curves.easeOutBack.transform(_motion.value);
                        final soft = Curves.easeOut.transform(_motion.value);
                        return switch (_current.motion) {
                          _ShapeMotion.bounce => Transform.scale(
                              scale: 0.86 + 0.14 * t,
                              child: child,
                            ),
                          _ShapeMotion.tilt => Transform.rotate(
                              angle: (1 - soft) * -0.14,
                              child: Transform.scale(
                                scale: 0.94 + 0.06 * soft,
                                child: child,
                              ),
                            ),
                          _ShapeMotion.soft => Transform.translate(
                              offset: Offset(0, (1 - soft) * 14),
                              child: Opacity(
                                opacity: 0.55 + 0.45 * soft,
                                child: child,
                              ),
                            ),
                          _ShapeMotion.clap => Transform.scale(
                              scale: 0.9 + 0.1 * t,
                              child: child,
                            ),
                        };
                      },
                      child: _CharacterStack(
                        bodyAsset: _bodyAsset,
                        faceAsset:
                            'assets/kenney_shapes/faces/face_${_current.face}.png',
                        leftHandAsset: _handAsset(_current.leftHand),
                        rightHandAsset: _handAsset(_current.rightHand),
                        clap: _current.motion == _ShapeMotion.clap,
                        motion: _motion,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _current.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _current.eventHint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                ],
              ),
            ),
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
              for (final mood in _reactions)
                ChoiceChip(
                  label: Text(mood.label),
                  selected: _current.id == mood.id,
                  onSelected: (_) => _select(mood),
                ),
            ],
          ),
          const SizedBox(height: 20),
          Text('All faces', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          GridView.count(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisCount: 6,
            mainAxisSpacing: 6,
            crossAxisSpacing: 6,
            children: [
              for (final letter in [
                'a',
                'b',
                'c',
                'd',
                'e',
                'f',
                'g',
                'h',
                'i',
                'j',
                'k',
                'l',
              ])
                Material(
                  color: _current.face == letter
                      ? const Color(0xFFE8F3EF)
                      : const Color(0xFF1A1F2C),
                  borderRadius: BorderRadius.circular(10),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(10),
                    onTap: () => _select(
                      _ShapeMood(
                        id: 'face_$letter',
                        label: 'Face $letter',
                        face: letter,
                        eventHint: 'Browse pack face',
                      ),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(6),
                      child: Image.asset(
                        'assets/kenney_shapes/faces/face_$letter.png',
                        fit: BoxFit.contain,
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            'Source: Kenney · https://kenney.nl/assets/shape-characters · CC0 '
            '(attribution optional). Next up: Rabbit state-machine Lottie.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}

class _CharacterStack extends StatelessWidget {
  const _CharacterStack({
    required this.bodyAsset,
    required this.faceAsset,
    required this.leftHandAsset,
    required this.rightHandAsset,
    required this.clap,
    required this.motion,
  });

  final String bodyAsset;
  final String faceAsset;
  final String leftHandAsset;
  final String rightHandAsset;
  final bool clap;
  final AnimationController motion;

  @override
  Widget build(BuildContext context) {
    final clapT = Curves.easeOut.transform(motion.value);
    final handY = clap ? -18.0 * clapT : 0.0;
    final handSpread = clap ? 10.0 * clapT : 0.0;

    return Stack(
      alignment: Alignment.center,
      children: [
        // Left hand
        Positioned(
          left: 18 - handSpread,
          top: 110 + handY,
          child: Image.asset(leftHandAsset, width: 56, height: 56),
        ),
        // Right hand (mirrored)
        Positioned(
          right: 18 - handSpread,
          top: 110 + handY,
          child: Transform.flip(
            flipX: true,
            child: Image.asset(rightHandAsset, width: 56, height: 56),
          ),
        ),
        // Body
        Image.asset(bodyAsset, width: 180, height: 180),
        // Face overlay
        Positioned(
          top: 58,
          child: AnimatedSwitcher(
            duration: const Duration(milliseconds: 180),
            child: Image.asset(
              faceAsset,
              key: ValueKey(faceAsset),
              width: 92,
              height: 92,
            ),
          ),
        ),
      ],
    );
  }
}
