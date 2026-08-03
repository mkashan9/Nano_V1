import 'package:flutter/widgets.dart';
import 'package:nano_domain/nano_domain.dart';

import '../l10n/nano_locale_scope.dart';
import 'companion_controller.dart';
import 'companion_pose_pack.dart';
import 'companion_scene_anchor.dart';

/// Announces a home-surface reaction and paints it on a hero card (CMP-04).
///
/// Keeps layout stable: the hero stays full width; the companion is a positioned
/// overlay in the lower-right rather than a separate inline stage row.
class CompanionHomeHeroScene extends StatefulWidget {
  const CompanionHomeHeroScene({
    super.key,
    required this.hero,
    this.entryEvent,
    this.seed = 0,
    this.alignment = CompanionSceneAnchorAlignment.lowerRight,
    this.maxWidthFraction = 0.34,
  });

  final Widget hero;
  final CompanionEvent? entryEvent;
  final int seed;
  final CompanionSceneAnchorAlignment alignment;
  final double maxWidthFraction;

  @override
  State<CompanionHomeHeroScene> createState() => _CompanionHomeHeroSceneState();
}

class _CompanionHomeHeroSceneState extends State<CompanionHomeHeroScene> {
  var _announced = false;
  CompanionController? _announcedTo;

  static const _surface = CompanionSurface.home;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final controller = NanoCompanionScope.maybeOf(context);
    final placement = CompanionPlacementPolicy.resolve(
      surface: _surface,
      junior: true,
    );
    if (controller == null || !placement.isVisible) return;
    if (_announced && identical(controller, _announcedTo)) return;
    _announced = true;
    _announcedTo = controller;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || !identical(controller, _announcedTo)) return;
      final event = widget.entryEvent;
      if (event == null) {
        controller.enterSurface(_surface);
      } else {
        controller.report(event, surface: _surface, seed: widget.seed);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = NanoCompanionScope.maybeOf(context);
    final placement = CompanionPlacementPolicy.resolve(
      surface: _surface,
      junior: true,
    );
    final reaction = controller?.reaction;
    final visible = controller != null &&
        placement.isVisible &&
        controller.isCurrent(_surface) &&
        reaction != null;

    final active = visible ? reaction : null;
    final activeController = visible ? controller : null;

    final locale =
        NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final caption = active?.captionFor(
      locale,
      companionName: active.companionName,
    );

    final staticAsset =
        active == null ? null : CompanionPosePack.assetFor(active.mood);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        widget.hero,
        Positioned.fill(
          child: CompanionSceneAnchor(
            visible: visible,
            alignment: widget.alignment,
            maxWidthFraction: widget.maxWidthFraction,
            imageAsset: staticAsset,
            networkImageUrl: activeController?.artUrl,
            clipView: activeController?.clipView,
            caption: active?.showsCaption == true ? caption : null,
            onDismiss: activeController?.dismiss,
            semanticLabel: active?.companionName,
          ),
        ),
      ],
    );
  }
}
