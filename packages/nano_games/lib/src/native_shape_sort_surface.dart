import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:nano_games/src/game_bridge_controller.dart';
import 'package:nano_games/src/game_feedback.dart';

/// Flutter-native Shape Sort fixture (`fixture://shape_sort`).
class NativeShapeSortSurface extends StatefulWidget {
  const NativeShapeSortSurface({
    super.key,
    required this.bridge,
    this.feedback,
    this.autoReady = true,
  });

  final GameBridgeController bridge;
  final GameFeedbackSink? feedback;
  final bool autoReady;

  @override
  State<NativeShapeSortSurface> createState() => _NativeShapeSortSurfaceState();
}

class _NativeShapeSortSurfaceState extends State<NativeShapeSortSurface> {
  static const _targets = ['circle', 'square', 'triangle'];
  late List<_SortChip> _chips;
  String? _selectedId;
  var _correct = 0;
  DateTime? _startedAt;

  @override
  void initState() {
    super.initState();
    _chips = [
      const _SortChip(id: 'a', shape: 'circle'),
      const _SortChip(id: 'b', shape: 'square'),
      const _SortChip(id: 'c', shape: 'triangle'),
    ];
    if (widget.autoReady) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        widget.bridge.handleInbound({'type': 'ready'});
      });
    }
  }

  void _selectChip(String chipId) {
    setState(() => _selectedId = chipId);
  }

  Future<void> _placeOn(String target) async {
    final selected = _selectedId;
    if (selected == null) return;
    final chip = _chips.cast<_SortChip?>().firstWhere(
          (c) => c?.id == selected,
          orElse: () => null,
        );
    if (chip == null || chip.placed) return;
    _startedAt ??= DateTime.now().toUtc();
    final ok = chip.shape == target;
    setState(() {
      _chips = [
        for (final c in _chips)
          if (c.id == selected) c.copyWith(placed: true, correct: ok) else c,
      ];
      _selectedId = null;
      if (ok) _correct += 1;
    });
    widget.bridge.handleInbound({
      'type': 'progress',
      'payload': {'checkpoint': _correct, 'last_ok': ok},
    });
    await widget.feedback?.tick();
  }

  Future<void> _finish() async {
    final started = _startedAt ?? DateTime.now().toUtc();
    final duration =
        DateTime.now().toUtc().difference(started).inMilliseconds;
    widget.bridge.handleInbound({
      'type': 'completed',
      'payload': {
        'session_id': widget.bridge.session.sessionId,
        'raw_score': _correct,
        'duration_ms': duration,
        'metrics': {'correct': _correct, 'total': _chips.length},
        'nonce': 'native-${widget.bridge.session.sessionId}-$_correct',
      },
    });
    await widget.feedback?.success();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final remaining = _chips.where((c) => !c.placed).toList();
    final quiet = widget.bridge.settings.classroomMode;
    return Material(
      color: theme.colorScheme.surfaceContainerHighest,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              widget.bridge.session.titleEn,
              style: theme.textTheme.titleLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              quiet
                  ? 'Native Flutter host · classroom quiet · sorted $_correct / ${_chips.length}'
                  : 'Native Flutter host · sorted $_correct / ${_chips.length}',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final target in _targets)
                  OutlinedButton(
                    key: ValueKey('bin-$target'),
                    onPressed:
                        _selectedId == null ? null : () => _placeOn(target),
                    child: Text('bin $target'),
                  ),
              ],
            ),
            const SizedBox(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: [
                for (final chip in remaining)
                  FilledButton(
                    key: ValueKey('chip-${chip.shape}'),
                    onPressed: () => _selectChip(chip.id),
                    style: FilledButton.styleFrom(
                      backgroundColor: _selectedId == chip.id
                          ? theme.colorScheme.tertiary
                          : null,
                    ),
                    child: Text('chip ${chip.shape}'),
                  ),
              ],
            ),
            const Spacer(),
            OutlinedButton(
              onPressed: remaining.isEmpty ? _finish : null,
              child: const Text('Finish'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SortChip {
  const _SortChip({
    required this.id,
    required this.shape,
    this.placed = false,
    this.correct = false,
  });

  final String id;
  final String shape;
  final bool placed;
  final bool correct;

  _SortChip copyWith({bool? placed, bool? correct}) => _SortChip(
        id: id,
        shape: shape,
        placed: placed ?? this.placed,
        correct: correct ?? this.correct,
      );
}

bool canUseNativeFlutterSurface(GameSessionStart session) =>
    session.entryKind == GameEntryKind.flutter &&
    session.isFixture &&
    GameOriginPolicy.allowsNavigation(
      allowedOrigins: session.allowedOrigins,
      url: session.entryRef,
    );
