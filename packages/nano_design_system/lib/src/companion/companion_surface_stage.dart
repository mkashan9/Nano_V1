import 'package:flutter/widgets.dart';
import 'package:nano_domain/nano_domain.dart';

import '../components/companion_stage.dart';
import '../tokens/nano_spacing.dart';
import 'companion_controller.dart';

/// Places the session companion on one surface (CMP-03).
///
/// A screen states which surface it is and, optionally, the moment worth
/// reporting on arrival. Everything else — mode, density, cooldowns, the session
/// budget, Classroom Mode — is decided by the shared controller, so no screen
/// has to know the rules or pick a size.
class CompanionSurfaceStage extends StatefulWidget {
  const CompanionSurfaceStage({
    super.key,
    required this.surface,
    required this.junior,
    this.entryEvent,
    this.seed = 0,
    this.action,
    this.dismissible = true,
  });

  final CompanionSurface surface;
  final bool junior;

  /// Reported once when this surface appears.
  final CompanionEvent? entryEvent;
  final int seed;

  /// Optional primary action for a story-card moment.
  final Widget? action;
  final bool dismissible;

  @override
  State<CompanionSurfaceStage> createState() => _CompanionSurfaceStageState();
}

class _CompanionSurfaceStageState extends State<CompanionSurfaceStage> {
  var _announced = false;

  /// The controller we last announced to. Replacing the session companion
  /// (a Junior/Senior flip, a rename) builds a fresh controller with no
  /// reaction; without noticing the identity change the stage would stay
  /// silent forever because [_announced] is already true.
  CompanionController? _announcedTo;

  CompanionPlacement get _placement => CompanionPlacementPolicy.resolve(
        surface: widget.surface,
        junior: widget.junior,
      );

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = NanoCompanionScope.maybeOf(context);
    if (controller == null || !_placement.isVisible) return;
    if (_announced && identical(controller, _announcedTo)) return;
    _announced = true;
    _announcedTo = controller;
    // After this frame: entering a surface notifies listeners, and this one is
    // still building.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(controller, _announcedTo)) return;
      final event = widget.entryEvent;
      if (event == null) {
        controller.enterSurface(widget.surface);
      } else {
        controller.report(event, surface: widget.surface, seed: widget.seed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = NanoCompanionScope.maybeOf(context);
    final placement = _placement;
    if (controller == null || !placement.isVisible) {
      return const SizedBox.shrink();
    }
    // One companion at a time: a screen left behind a pushed route goes quiet.
    if (!controller.isCurrent(widget.surface)) return const SizedBox.shrink();
    if (controller.reaction == null) return const SizedBox.shrink();
    // The gap belongs to the companion, so a page keeps its exact layout on the
    // frames where there is nothing to say.
    return Padding(
      padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
      child: CompanionStage(
        reaction: controller.reaction,
        placement: placement,
        action: widget.action,
        onDismiss: widget.dismissible ? controller.dismiss : null,
        // Only when a recording of these exact words exists and sound is allowed.
        onListen: controller.canSpeak ? controller.speak : null,
        // Only when an approved clip exists for this reaction and a player is
        // attached. Autoplay is forbidden: the learner asks, like Listen.
        clipAvailable: controller.canShowClip,
        onPlayClip: controller.canShowClip ? controller.playClip : null,
        // The approved picture when one has been published for this slot, and
        // the clip only while it is actually playing (MED-08).
        artUrl: controller.artUrl,
        clipView: controller.clipView,
      ),
    );
  }
}
