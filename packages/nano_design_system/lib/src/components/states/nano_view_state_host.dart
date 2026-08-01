import 'package:flutter/material.dart';
import 'package:nano_domain/nano_domain.dart';
import 'nano_empty_state.dart';
import 'nano_error_state.dart';
import 'nano_feature_disabled_state.dart';
import 'nano_loading_state.dart';
import 'nano_maintenance_state.dart';
import 'nano_offline_banner.dart';
import 'nano_permission_denied_state.dart';
import 'nano_suspended_state.dart';
import 'nano_sync_status_banner.dart';
import '../../companion/companion_surface_stage.dart';
import '../../tokens/nano_spacing.dart';

/// Maps [NanoViewState] to design-system chrome. Ready state shows [child].
///
/// MED-12: empty, error, and offline may carry the session companion via
/// [companionSurface] without ever covering the recovery action. The companion
/// sits above the chrome; the retry button stays where it was.
class NanoViewStateHost extends StatelessWidget {
  const NanoViewStateHost({
    super.key,
    required this.state,
    required this.child,
    this.onRetry,
    this.companionSurface,
    this.junior = true,
    this.companionEntryEvent = CompanionEvent.emptyState,
  });

  final NanoViewState state;
  final Widget child;
  final VoidCallback? onRetry;

  /// When set, empty / error / offline chrome include the session companion
  /// for this surface. Ready and loading leave it alone — ready has its own
  /// mounts, and a spinner is not a moment worth narrating.
  final CompanionSurface? companionSurface;
  final bool junior;
  final CompanionEvent companionEntryEvent;

  Widget? get _companion {
    final surface = companionSurface;
    if (surface == null) return null;
    return CompanionSurfaceStage(
      surface: surface,
      junior: junior,
      entryEvent: companionEntryEvent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      NanoViewReady() => child,
      NanoViewLoading(:final message) => NanoLoadingState(message: message),
      NanoViewEmpty(:final title, :final message) => _withCompanion(
          NanoEmptyState(title: title, message: message),
        ),
      NanoViewError(:final title, :final message, :final canRetry) =>
        _withCompanion(
          NanoErrorState(
            title: title,
            message: message,
            onRetry: canRetry ? onRetry : null,
          ),
        ),
      NanoViewSuspended(:final title, :final message) =>
        NanoSuspendedState(title: title, message: message),
      NanoViewMaintenance(:final title, :final message) =>
        NanoMaintenanceState(title: title, message: message),
      NanoViewPermissionDenied(:final title, :final message) =>
        NanoPermissionDeniedState(title: title, message: message),
      NanoViewFeatureDisabled(:final title, :final message) =>
        NanoFeatureDisabledState(title: title, message: message),
      NanoViewOffline(:final message, :final lastUpdatedLabel) => Column(
          children: [
            NanoOfflineBanner(
              message: message,
              lastUpdatedLabel: lastUpdatedLabel,
            ),
            if (_companion != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(
                  NanoSpacing.md,
                  NanoSpacing.sm,
                  NanoSpacing.md,
                  0,
                ),
                child: _companion,
              ),
            Expanded(child: child),
          ],
        ),
      NanoViewSyncing(:final message) => Column(
          children: [
            NanoSyncStatusBanner(
              phase: NanoSyncPhase.syncing,
              message: message,
            ),
            Expanded(child: child),
          ],
        ),
    };
  }

  /// Companion above the chrome, never instead of it. A recovery button that
  /// lived inside the empty/error widget stays exactly where it was.
  Widget _withCompanion(Widget chrome) {
    final companion = _companion;
    if (companion == null) return chrome;
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(
            NanoSpacing.md,
            NanoSpacing.md,
            NanoSpacing.md,
            0,
          ),
          child: companion,
        ),
        Expanded(child: chrome),
      ],
    );
  }
}
