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

/// Maps [NanoViewState] to design-system chrome. Ready state shows [child].
class NanoViewStateHost extends StatelessWidget {
  const NanoViewStateHost({
    super.key,
    required this.state,
    required this.child,
    this.onRetry,
  });

  final NanoViewState state;
  final Widget child;
  final VoidCallback? onRetry;

  @override
  Widget build(BuildContext context) {
    return switch (state) {
      NanoViewReady() => child,
      NanoViewLoading(:final message) => NanoLoadingState(message: message),
      NanoViewEmpty(:final title, :final message) =>
        NanoEmptyState(title: title, message: message),
      NanoViewError(:final title, :final message, :final canRetry) =>
        NanoErrorState(
          title: title,
          message: message,
          onRetry: canRetry ? onRetry : null,
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
}
