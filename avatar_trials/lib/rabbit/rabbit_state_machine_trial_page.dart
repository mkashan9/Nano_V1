import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

enum _RabbitState {
  idle('Idle', 'Waiting calmly'),
  greet('Greet', 'Student opens app'),
  happy('Happy', 'Correct answer'),
  celebrate('Celebrate', 'Quiz complete'),
  thinking('Thinking', 'Hint / processing'),
  sad('Sad', 'Gentle retry'),
  sleep('Sleep', 'Inactive for a while');

  const _RabbitState(this.label, this.hint);
  final String label;
  final String hint;
}

enum _RabbitEvent {
  openApp('Open app'),
  correct('Correct'),
  complete('Complete'),
  think('Think'),
  wrong('Wrong'),
  wait('Wait'),
  nap('Nap'),
  wake('Wake'),
  tap('Tap mascot');

  const _RabbitEvent(this.label);
  final String label;
}

/// Trial 2 (simple 2D): local rabbit state-machine style interactions.
class RabbitStateMachineTrialPage extends StatefulWidget {
  const RabbitStateMachineTrialPage({super.key});

  @override
  State<RabbitStateMachineTrialPage> createState() =>
      _RabbitStateMachineTrialPageState();
}

class _RabbitStateMachineTrialPageState extends State<RabbitStateMachineTrialPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _tick;
  _RabbitState _state = _RabbitState.idle;
  String _lastEvent = 'none';

  @override
  void initState() {
    super.initState();
    _tick = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _tick.dispose();
    super.dispose();
  }

  Set<_RabbitEvent> get _allowedEvents => switch (_state) {
        _RabbitState.idle => {
            _RabbitEvent.openApp,
            _RabbitEvent.correct,
            _RabbitEvent.think,
            _RabbitEvent.wrong,
            _RabbitEvent.nap,
            _RabbitEvent.tap,
          },
        _RabbitState.greet => {
            _RabbitEvent.correct,
            _RabbitEvent.think,
            _RabbitEvent.wait,
            _RabbitEvent.tap,
          },
        _RabbitState.happy => {
            _RabbitEvent.complete,
            _RabbitEvent.wait,
            _RabbitEvent.tap,
          },
        _RabbitState.celebrate => {
            _RabbitEvent.wait,
            _RabbitEvent.tap,
          },
        _RabbitState.thinking => {
            _RabbitEvent.correct,
            _RabbitEvent.wrong,
            _RabbitEvent.wait,
            _RabbitEvent.tap,
          },
        _RabbitState.sad => {
            _RabbitEvent.think,
            _RabbitEvent.wait,
            _RabbitEvent.tap,
          },
        _RabbitState.sleep => {
            _RabbitEvent.wake,
            _RabbitEvent.tap,
          },
      };

  void _dispatch(_RabbitEvent event) {
    if (!_allowedEvents.contains(event)) return;
    final next = switch (event) {
      _RabbitEvent.openApp => _RabbitState.greet,
      _RabbitEvent.correct => _RabbitState.happy,
      _RabbitEvent.complete => _RabbitState.celebrate,
      _RabbitEvent.think => _RabbitState.thinking,
      _RabbitEvent.wrong => _RabbitState.sad,
      _RabbitEvent.wait => _RabbitState.idle,
      _RabbitEvent.nap => _RabbitState.sleep,
      _RabbitEvent.wake => _RabbitState.idle,
      _RabbitEvent.tap => switch (_state) {
          _RabbitState.sleep => _RabbitState.idle,
          _RabbitState.sad => _RabbitState.thinking,
          _RabbitState.thinking => _RabbitState.happy,
          _ => _RabbitState.greet,
        },
    };
    setState(() {
      _lastEvent = event.label;
      _state = next;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rabbit State Machine'),
        centerTitle: true,
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
        children: [
          Text(
            'Local rabbit fallback trial (LottieFiles page is bot-protected right now).\n'
            'Evaluates the same concept: event-driven mascot state transitions.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey.shade700, height: 1.35),
          ),
          const SizedBox(height: 14),
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
                    height: 250,
                    child: AnimatedBuilder(
                      animation: _tick,
                      builder: (context, child) {
                        final t = _tick.value;
                        final sin = math.sin(2 * math.pi * t);
                        final cos = math.cos(2 * math.pi * t);
                        final scale = switch (_state) {
                          _RabbitState.happy => 1 + 0.06 * sin.abs(),
                          _RabbitState.celebrate => 1 + 0.1 * sin.abs(),
                          _RabbitState.sleep => 0.92 + 0.03 * cos,
                          _ => 1.0,
                        };
                        final y = switch (_state) {
                          _RabbitState.idle => 4 * sin,
                          _RabbitState.greet => 6 * sin,
                          _RabbitState.thinking => 3 * sin,
                          _RabbitState.sad => 10 * (1 - t),
                          _RabbitState.sleep => 8 * cos.abs(),
                          _ => 0.0,
                        };
                        final rotate = switch (_state) {
                          _RabbitState.greet => 0.08 * sin,
                          _RabbitState.thinking => 0.12 * sin,
                          _RabbitState.celebrate => 0.24 * sin,
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
                      child: Stack(
                        alignment: Alignment.center,
                        children: [
                          SvgPicture.asset(
                            'assets/rabbit_sm/rabbit.svg',
                            width: 190,
                            height: 190,
                          ),
                          if (_state == _RabbitState.sleep)
                            const Positioned(
                              right: 40,
                              top: 30,
                              child: Text(
                                'Zz',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 26,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _state.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _state.hint,
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.grey.shade300),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Last event: $_lastEvent',
                    style: TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text('State-machine events',
              style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: [
              for (final event in _RabbitEvent.values)
                ChoiceChip(
                  label: Text(event.label),
                  selected: false,
                  onSelected: _allowedEvents.contains(event)
                      ? (_) => _dispatch(event)
                      : null,
                ),
            ],
          ),
          const SizedBox(height: 16),
          DecoratedBox(
            decoration: BoxDecoration(
              color: const Color(0xFFFFF4E5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Padding(
              padding: EdgeInsets.all(12),
              child: Text(
                'This validates the interaction model (state + allowed transitions). '
                'When we can fetch the original dotLottie rabbit, we can plug these '
                'same events into real state-machine inputs.',
              ),
            ),
          ),
        ],
      ),
    );
  }
}
