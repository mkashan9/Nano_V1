import 'package:flutter/material.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

class AccessibilitySettingsPage extends StatelessWidget {
  const AccessibilitySettingsPage({
    super.key,
    required this.onChanged,
  });

  final ValueChanged<AccessibilityPreferences> onChanged;

  @override
  Widget build(BuildContext context) {
    final scope = NanoAccessibilityScope.of(context);
    final preferences = scope.preferences;
    final feedback = scope.feedback;
    return NanoScaffold(
      appBar: AppBar(title: const Text('Accessibility')),
      body: ListView(
        children: [
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Sound effects'),
            subtitle: Text(
              preferences.classroomMode
                  ? 'Paused by Classroom Mode'
                  : 'UI and companion cues',
            ),
            value: preferences.soundEnabled,
            onChanged: preferences.classroomMode
                ? null
                : (v) => onChanged(preferences.copyWith(soundEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Haptics'),
            value: preferences.hapticsEnabled,
            onChanged: preferences.classroomMode
                ? null
                : (v) => onChanged(preferences.copyWith(hapticsEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Reduced motion'),
            subtitle: const Text('Prefer fades / static changes'),
            value: preferences.reducedMotion,
            onChanged: (v) =>
                onChanged(preferences.copyWith(reducedMotion: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Captions'),
            subtitle: const Text('Show captions when speech is used'),
            value: preferences.captionsEnabled,
            onChanged: (v) =>
                onChanged(preferences.copyWith(captionsEnabled: v)),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Classroom Mode'),
            subtitle: const Text(
              'Quiet feedback and reduced non-essential motion',
            ),
            value: preferences.classroomMode,
            onChanged: (v) =>
                onChanged(preferences.copyWith(classroomMode: v)),
          ),
          const SizedBox(height: NanoSpacing.md),
          Text('Text size', style: Theme.of(context).textTheme.titleMedium),
          Slider(
            value: preferences.textScale.clamp(0.85, 1.6),
            min: 0.85,
            max: 1.6,
            divisions: 15,
            label: preferences.textScale.toStringAsFixed(2),
            onChanged: (v) => onChanged(preferences.copyWith(textScale: v)),
          ),
          const SizedBox(height: NanoSpacing.lg),
          Text('Try feedback', style: Theme.of(context).textTheme.titleMedium),
          const SizedBox(height: NanoSpacing.sm),
          Wrap(
            spacing: NanoSpacing.sm,
            children: [
              NanoAccessibleTarget(
                label: 'Play success feedback',
                onTap: () => feedback.success(),
                child: const Text('Success'),
              ),
              NanoAccessibleTarget(
                label: 'Play error feedback',
                onTap: () => feedback.error(),
                child: const Text('Error'),
              ),
            ],
          ),
          const SizedBox(height: NanoSpacing.lg),
          _MotionDemo(reduced: preferences.effectiveReducedMotion),
          if (preferences.captionsEnabled) ...[
            const SizedBox(height: NanoSpacing.lg),
            const NanoOfflineBanner(
              message: 'Caption sample: “Great job — keep going!”',
            ),
          ],
        ],
      ),
    );
  }
}

class _MotionDemo extends StatefulWidget {
  const _MotionDemo({required this.reduced});

  final bool reduced;

  @override
  State<_MotionDemo> createState() => _MotionDemoState();
}

class _MotionDemoState extends State<_MotionDemo>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: NanoMotion.slow,
    )..repeat(reverse: true);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final duration = NanoMotion.resolve(context, NanoMotion.slow);
    _controller.duration = duration == Duration.zero
        ? const Duration(milliseconds: 1)
        : duration;
    if (widget.reduced || duration == Duration.zero) {
      _controller.stop();
      _controller.value = 1;
    } else if (!_controller.isAnimating) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(covariant _MotionDemo oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.reduced) {
      _controller.stop();
      _controller.value = 1;
    } else {
      _controller.duration = NanoMotion.slow;
      _controller.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Motion sample', style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: NanoSpacing.sm),
        FadeTransition(
          opacity: widget.reduced
              ? const AlwaysStoppedAnimation(1)
              : _controller,
          child: Container(
            height: 64,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: NanoColors.brandPrimary.withValues(alpha: 0.35),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              widget.reduced ? 'Static (reduced motion)' : 'Animating…',
            ),
          ),
        ),
      ],
    );
  }
}
