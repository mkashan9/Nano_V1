import 'dart:math' as math;

import 'package:flutter/material.dart';

enum _RaccoonClip {
  idle('Idle', 'assets/null_painter_raccoon/animations/idle.gif', 'Waiting / neutral'),
  walk('Walk', 'assets/null_painter_raccoon/animations/walk.gif', 'Entering screen'),
  run('Run', 'assets/null_painter_raccoon/animations/run.gif', 'Fast transition'),
  jump('Jump', 'assets/null_painter_raccoon/animations/jump.gif', 'Correct answer'),
  celebrate(
    'Celebrate',
    'assets/null_painter_raccoon/animations/victory-dance.gif',
    'Quiz completed',
  ),
  crouch('Crouch', 'assets/null_painter_raccoon/animations/crouch.gif', 'Gentle sad / tired base'),
  slide('Slide', 'assets/null_painter_raccoon/animations/slide.gif', 'Optional movement'),
  ko('KO', 'assets/null_painter_raccoon/animations/ko.gif', 'Offline / disabled state');

  const _RaccoonClip(this.label, this.asset, this.eventHint);
  final String label;
  final String asset;
  final String eventHint;
}

class NullPainterRaccoonTrialPage extends StatefulWidget {
  const NullPainterRaccoonTrialPage({super.key});

  @override
  State<NullPainterRaccoonTrialPage> createState() =>
      _NullPainterRaccoonTrialPageState();
}

class _NullPainterRaccoonTrialPageState extends State<NullPainterRaccoonTrialPage>
    with SingleTickerProviderStateMixin {
  _RaccoonClip _current = _RaccoonClip.idle;
  late final AnimationController _motion;

  @override
  void initState() {
    super.initState();
    _motion = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 950),
    )..repeat();
  }

  @override
  void dispose() {
    _motion.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Null Painter Raccoon'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Full-body raccoon with 8 ready animation loops (CC BY 4.0).\n'
            'Local GIF sequences + editable SVG source, fully offline.',
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
              padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 12),
              child: Column(
                children: [
                  SizedBox(
                    height: 300,
                    child: AnimatedBuilder(
                      animation: _motion,
                      builder: (context, child) {
                        final t = _motion.value;
                        final sin = math.sin(2 * math.pi * t);
                        final scale = switch (_current) {
                          _RaccoonClip.jump => 0.95 + 0.07 * sin.abs(),
                          _RaccoonClip.celebrate => 0.95 + 0.09 * sin.abs(),
                          _RaccoonClip.ko => 0.94 + 0.02 * (1 - t),
                          _ => 1.0,
                        };
                        final y = switch (_current) {
                          _RaccoonClip.idle => 4 * sin,
                          _RaccoonClip.crouch => 6 * sin.abs(),
                          _RaccoonClip.jump => -10 * sin.abs(),
                          _RaccoonClip.ko => 10 * (1 - t),
                          _ => 0.0,
                        };
                        final rotate = switch (_current) {
                          _RaccoonClip.celebrate => 0.08 * sin,
                          _RaccoonClip.slide => 0.03 * sin,
                          _RaccoonClip.run => 0.02 * sin,
                          _ => 0.0,
                        };
                        return Transform.translate(
                          offset: Offset(0, y),
                          child: Transform.rotate(
                            angle: rotate,
                            child: Transform.scale(scale: scale, child: child),
                          ),
                        );
                      },
                      child: AnimatedSwitcher(
                        duration: const Duration(milliseconds: 220),
                        child: Image.asset(
                          _current.asset,
                          key: ValueKey(_current.asset),
                          fit: BoxFit.contain,
                          filterQuality: FilterQuality.medium,
                        ),
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
          Text('Ready clips', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final clip in _RaccoonClip.values)
                ChoiceChip(
                  label: Text(clip.label),
                  selected: _current == clip,
                  onSelected: (_) => setState(() => _current = clip),
                ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFE7F6EE),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'Best use now: idle, walk, jump, celebrate, crouch. '
                'Next production pass: add wave, thinking, confused, point-left, point-right '
                'from the included raccoon SVG parts and export matching loops.',
                style: TextStyle(height: 1.35),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Source: null painter · itch.io/cute-raccoon-2d-game-sprite-and-animations · CC BY 4.0',
            style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
          ),
        ],
      ),
    );
  }
}
