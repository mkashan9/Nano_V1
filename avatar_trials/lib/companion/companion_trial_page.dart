import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'reaction_controller.dart';

/// Trial 2: Yofardev-style companion engine (no speech / lip-sync).
///
/// Uses Yofardev's layered avatar base image for visual reference only.
/// Reaction queue / interrupt / idle scheduling are the reusable engine bits.
class CompanionTrialPage extends StatefulWidget {
  const CompanionTrialPage({super.key});

  @override
  State<CompanionTrialPage> createState() => _CompanionTrialPageState();
}

class _CompanionTrialPageState extends State<CompanionTrialPage>
    with TickerProviderStateMixin {
  late final CompanionReactionController _reactions;
  late final AnimationController _bob;
  late final AnimationController _gesture;
  Timer? _blinkTimer;
  String _eyeState = 'open';

  @override
  void initState() {
    super.initState();
    _reactions = CompanionReactionController()..addListener(_onReaction);

    _bob = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    )..repeat(reverse: true);

    _gesture = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _blinkTimer = Timer.periodic(const Duration(seconds: 4), (_) => _blink());
  }

  void _onReaction() {
    if (!mounted) return;
    setState(() {});
    if (_reactions.mood != CompanionMood.idle) {
      _gesture
        ..duration = const Duration(milliseconds: 650)
        ..forward(from: 0);
    }
  }

  Future<void> _blink() async {
    if (!mounted || _reactions.mood == CompanionMood.thinking) return;
    setState(() => _eyeState = 'half_closed');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!mounted) return;
    setState(() => _eyeState = 'closed');
    await Future<void>.delayed(const Duration(milliseconds: 110));
    if (!mounted) return;
    setState(() => _eyeState = 'half_closed');
    await Future<void>.delayed(const Duration(milliseconds: 30));
    if (!mounted) return;
    setState(() => _eyeState = 'open');
  }

  @override
  void dispose() {
    _blinkTimer?.cancel();
    _reactions
      ..removeListener(_onReaction)
      ..dispose();
    _bob.dispose();
    _gesture.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Yofardev-style companion'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Engine trial only — no talking, no lip-sync.\n'
            'Tap reactions to queue gestures; Interrupt clears the queue.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 8),
          Text(
            'Mood: ${_label(_reactions.mood)}'
            '${_reactions.queueLength > 0 ? '  ·  queued ${_reactions.queueLength}' : ''}',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 360,
            child: AnimatedBuilder(
              animation: Listenable.merge([_bob, _gesture]),
              builder: (context, child) {
                final mood = _reactions.mood;
                final t = _gesture.value;
                final bob = math.sin(_bob.value * math.pi) * 8;

                double dy = bob;
                double dx = 0;
                double scale = 1;
                double angle = 0;

                switch (mood) {
                  case CompanionMood.idle:
                    dy = bob;
                  case CompanionMood.happy:
                    dy = bob - 18 * math.sin(t * math.pi);
                    scale = 1 + 0.06 * math.sin(t * math.pi);
                  case CompanionMood.thinking:
                    dy = bob - 6;
                    angle = -0.08 * math.sin(t * math.pi);
                  case CompanionMood.celebrate:
                    dy = bob - 28 * math.sin(t * math.pi * 2);
                    scale = 1 + 0.1 * math.sin(t * math.pi);
                    angle = 0.12 * math.sin(t * math.pi * 3);
                  case CompanionMood.encourage:
                    dx = 10 * math.sin(t * math.pi * 2);
                    scale = 1 + 0.04 * math.sin(t * math.pi);
                  case CompanionMood.confused:
                    angle = 0.15 * math.sin(t * math.pi * 2);
                    dy = bob + 4;
                  case CompanionMood.wave:
                    dx = 16 * math.sin(t * math.pi * 2);
                    angle = 0.1 * math.sin(t * math.pi * 2);
                }

                return Transform.translate(
                  offset: Offset(dx, dy),
                  child: Transform.rotate(
                    angle: angle,
                    child: Transform.scale(
                      scale: scale,
                      child: child,
                    ),
                  ),
                );
              },
              child: _AvatarStage(eyeState: _eyeState),
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final mood in const [
                CompanionMood.happy,
                CompanionMood.thinking,
                CompanionMood.celebrate,
                CompanionMood.encourage,
                CompanionMood.confused,
                CompanionMood.wave,
              ])
                FilledButton.tonal(
                  onPressed: () => _reactions.play(mood),
                  child: Text(_label(mood)),
                ),
              FilledButton(
                onPressed: () => _reactions.interrupt(),
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFB45309),
                ),
                child: const Text('Interrupt'),
              ),
            ],
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),
          const Text(
            'What this reuses from Yofardev',
            style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
          const SizedBox(height: 8),
          Text(
            '• Idle scheduling + blink overlays\n'
            '• Reaction queue + interrupt\n'
            '• Asset/state switching via mood\n'
            '• Gesture motion with Flutter animations\n\n'
            'Removed for Nori: TTS, lip-sync, chat UI, LLM, mouth amplitude.',
            style: TextStyle(color: Colors.grey.shade800, height: 1.4),
          ),
          const SizedBox(height: 16),
          OutlinedButton.icon(
            onPressed: () async {
              const url = 'https://yofardev-ai.web.app';
              await Clipboard.setData(const ClipboardData(text: url));
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Copied $url — paste in a browser tab'),
                  ),
                );
              }
            },
            icon: const Icon(Icons.link),
            label: const Text('Copy original Yofardev web demo URL'),
          ),
          const SizedBox(height: 8),
          Text(
            'Full Yofardev needs API keys and works best on Android. '
            'Artwork here is their sample base for engine testing only — '
            'Nori would use your own assets.',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }

  String _label(CompanionMood mood) {
    switch (mood) {
      case CompanionMood.idle:
        return 'Idle';
      case CompanionMood.happy:
        return 'Happy';
      case CompanionMood.thinking:
        return 'Thinking';
      case CompanionMood.celebrate:
        return 'Celebrate';
      case CompanionMood.encourage:
        return 'Encourage';
      case CompanionMood.confused:
        return 'Confused';
      case CompanionMood.wave:
        return 'Wave';
    }
  }
}

class _AvatarStage extends StatelessWidget {
  const _AvatarStage({required this.eyeState});

  final String eyeState;

  @override
  Widget build(BuildContext context) {
    // Yofardev canvas is 1024x1280; eye overlays sit near eyesX/eyesY.
    const canvasW = 1024.0;
    const canvasH = 1280.0;
    const eyesX = 226.0;
    const eyesY = 428.0;

    return Center(
      child: AspectRatio(
        aspectRatio: canvasW / canvasH,
        child: LayoutBuilder(
          builder: (context, constraints) {
            final scale = constraints.maxWidth / canvasW;
            return DecoratedBox(
              decoration: BoxDecoration(
                color: const Color(0xFFE8F3EF),
                borderRadius: BorderRadius.circular(24),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(24),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    Image.asset(
                      'assets/yofardev/base.png',
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                    ),
                    if (eyeState != 'open')
                      Positioned(
                        left: eyesX * scale,
                        top: eyesY * scale,
                        child: Image.asset(
                          eyeState == 'closed'
                              ? 'assets/yofardev/closed_eyes.png'
                              : 'assets/yofardev/half_closed_eyes.png',
                          width: 420 * scale,
                          fit: BoxFit.fitWidth,
                        ),
                      ),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
