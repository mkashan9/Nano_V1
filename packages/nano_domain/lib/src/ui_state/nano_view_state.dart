/// Shared async / screen state contract for Views and ViewModels.
/// UI maps these to design-system state widgets (FND-05).
sealed class NanoViewState {
  const NanoViewState();
}

class NanoViewReady extends NanoViewState {
  const NanoViewReady();
}

class NanoViewLoading extends NanoViewState {
  const NanoViewLoading({this.message = 'Loading'});

  final String message;
}

class NanoViewEmpty extends NanoViewState {
  const NanoViewEmpty({
    this.title = 'Nothing here yet',
    this.message = 'Check back soon.',
  });

  final String title;
  final String message;
}

class NanoViewError extends NanoViewState {
  const NanoViewError({
    this.title = 'Something went wrong',
    this.message = 'Please try again.',
    this.canRetry = true,
  });

  final String title;
  final String message;
  final bool canRetry;
}

class NanoViewOffline extends NanoViewState {
  const NanoViewOffline({
    this.message = 'You are offline. Showing the last known information.',
    this.lastUpdatedLabel,
  });

  final String message;
  final String? lastUpdatedLabel;
}

class NanoViewSyncing extends NanoViewState {
  const NanoViewSyncing({this.message = 'Syncing…'});

  final String message;
}

class NanoViewSuspended extends NanoViewState {
  const NanoViewSuspended({
    this.title = 'Access paused',
    this.message = 'This account or school is temporarily suspended.',
  });

  final String title;
  final String message;
}

class NanoViewMaintenance extends NanoViewState {
  const NanoViewMaintenance({
    this.title = 'Under maintenance',
    this.message =
        'Nano is temporarily unavailable while we finish updates. Try again soon.',
  });

  final String title;
  final String message;
}

class NanoViewPermissionDenied extends NanoViewState {
  const NanoViewPermissionDenied({
    this.title = 'No access',
    this.message = 'You do not have permission to view this area.',
  });

  final String title;
  final String message;
}

class NanoViewFeatureDisabled extends NanoViewState {
  const NanoViewFeatureDisabled({
    this.title = 'Not available',
    this.message = 'This feature is turned off for your school or account.',
  });

  final String title;
  final String message;
}

extension NanoViewStateX on NanoViewState {
  bool get blocksContent => switch (this) {
        NanoViewReady() || NanoViewOffline() || NanoViewSyncing() => false,
        _ => true,
      };
}
