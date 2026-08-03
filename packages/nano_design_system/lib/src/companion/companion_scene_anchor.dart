import 'package:flutter/material.dart';

/// Scene-integrated companion presence (CMP-04).
///
/// Anchors art or a clip to a card/screen edge with soft edges and optional
/// entrance motion. Intentionally not a [CircleAvatar] badge.
class CompanionSceneAnchor extends StatefulWidget {
  const CompanionSceneAnchor({
    super.key,
    required this.art,
    this.clipView,
    this.caption,
    this.alignment = Alignment.bottomRight,
    this.maxWidthFraction = 0.32,
    this.maxHeight = 220,
    this.ignorePointer = true,
    this.reducedMotion = false,
    this.onDismiss,
    this.visible = true,
  });

  final Widget art;
  final Widget? clipView;
  final String? caption;
  final Alignment alignment;
  final double maxWidthFraction;
  final double maxHeight;
  final bool ignorePointer;
  final bool reducedMotion;
  final VoidCallback? onDismiss;
  final bool visible;

  @override
  State<CompanionSceneAnchor> createState() => _CompanionSceneAnchorState();
}

class _CompanionSceneAnchorState extends State<CompanionSceneAnchor>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 420),
  );

  @override
  void initState() {
    super.initState();
    if (widget.visible) {
      if (widget.reducedMotion) {
        _controller.value = 1;
      } else {
        _controller.forward();
      }
    }
  }

  @override
  void didUpdateWidget(covariant CompanionSceneAnchor oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.visible && !oldWidget.visible) {
      if (widget.reducedMotion) {
        _controller.value = 1;
      } else {
        _controller.forward(from: 0);
      }
    } else if (!widget.visible && oldWidget.visible) {
      _controller.reverse();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.visible && _controller.isDismissed) {
      return const SizedBox.shrink();
    }

    final width = MediaQuery.sizeOf(context).width * widget.maxWidthFraction;
    final slide = widget.reducedMotion
        ? const AlwaysStoppedAnimation(Offset.zero)
        : Tween<Offset>(
            begin: Offset(widget.alignment.x > 0 ? 0.18 : -0.18, 0.06),
            end: Offset.zero,
          ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic));

    Widget body = FadeTransition(
      opacity: _controller,
      child: SlideTransition(
        position: slide,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: width.clamp(72, 280),
            maxHeight: widget.maxHeight,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Flexible(
                child: ShaderMask(
                  blendMode: BlendMode.dstIn,
                  shaderCallback: (rect) {
                    return LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withValues(alpha: 0.15),
                        Colors.white,
                        Colors.white,
                        Colors.white.withValues(alpha: 0.85),
                      ],
                      stops: const [0, 0.12, 0.82, 1],
                    ).createShader(rect);
                  },
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF6B4CFF).withValues(alpha: 0.28),
                          blurRadius: 18,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(18),
                      child: ColoredBox(
                        color: const Color(0xFF0B0D1A).withValues(alpha: 0.35),
                        child: widget.reducedMotion || widget.clipView == null
                            ? widget.art
                            : widget.clipView!,
                      ),
                    ),
                  ),
                ),
              ),
              if (widget.caption != null && widget.caption!.isNotEmpty) ...[
                const SizedBox(height: 6),
                Text(
                  widget.caption!,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.25,
                  ),
                ),
              ],
              if (widget.onDismiss != null)
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    visualDensity: VisualDensity.compact,
                    onPressed: widget.onDismiss,
                    icon: const Icon(Icons.close, size: 16, color: Colors.white70),
                  ),
                ),
            ],
          ),
        ),
      ),
    );

    if (widget.ignorePointer) {
      body = IgnorePointer(child: body);
    }
    return body;
  }
}
