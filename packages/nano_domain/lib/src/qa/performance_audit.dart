/// QA-02 performance budgets and small-device smoke checklist.

enum PerformanceCheckStatus { pass, warn, fail }

class PerformanceAuditCheck {
  const PerformanceAuditCheck({
    required this.id,
    required this.title,
    required this.status,
    required this.detail,
  });

  final String id;
  final String title;
  final PerformanceCheckStatus status;
  final String detail;

  bool get passed => status != PerformanceCheckStatus.fail;
}

class PerformanceAuditReport {
  const PerformanceAuditReport({
    required this.checks,
    required this.generatedAt,
  });

  final List<PerformanceAuditCheck> checks;
  final DateTime generatedAt;

  bool get allPassed => checks.every((check) => check.passed);
  int get failCount => checks
      .where((check) => check.status == PerformanceCheckStatus.fail)
      .length;
}

/// Canonical smoke viewports (aligned with FND-03 / NanoBreakpoints).
abstract final class PerformanceViewports {
  static const smallPhoneWidth = 360.0;
  static const smallPhoneHeight = 640.0;
  static const largePhoneWidth = 430.0;
  static const tabletWidth = 768.0;
  static const textScaleSmoke = 1.3;
}

/// Soft budgets for pilot smoke (not a substitute for profiling tools).
abstract final class PerformanceBudgets {
  /// Documented first-content target for cold open on a small phone.
  static const firstContentfulFrameMs = 3000;

  /// Prefer keeping dense lists under this before virtualizing further.
  static const denseListWarnCount = 40;
}

/// Client-side layout density rules mirrored from FND-03 responsive columns.
abstract final class PerformanceLayoutPolicy {
  static int subjectColumns({
    required double width,
    required bool junior,
  }) {
    if (width < PerformanceViewports.tabletWidth) {
      return junior ? 2 : 1;
    }
    if (width < 1024) {
      return junior ? 3 : 2;
    }
    return junior ? 4 : 2;
  }

  static bool supportsSmallPhone(double width) =>
      width >= PerformanceViewports.smallPhoneWidth;
}

abstract final class PerformanceAuditPolicy {
  static PerformanceAuditReport evaluate({
    double width = PerformanceViewports.smallPhoneWidth,
    double textScale = 1.0,
    int denseListCount = 12,
    int? measuredFirstFrameMs,
    DateTime? now,
  }) {
    final checks = <PerformanceAuditCheck>[
      _viewportCheck(width),
      _juniorColumnsCheck(width),
      _seniorColumnsCheck(width),
      _textScaleCheck(textScale),
      _denseListCheck(denseListCount),
      _firstFrameCheck(measuredFirstFrameMs),
    ];
    return PerformanceAuditReport(
      checks: checks,
      generatedAt: now ?? DateTime.now().toUtc(),
    );
  }

  static PerformanceAuditCheck _viewportCheck(double width) {
    if (!PerformanceLayoutPolicy.supportsSmallPhone(width) &&
        width < PerformanceViewports.smallPhoneWidth) {
      return PerformanceAuditCheck(
        id: 'viewport.small_phone',
        title: 'Small-phone viewport supported',
        status: PerformanceCheckStatus.fail,
        detail:
            'Width $width is below ${PerformanceViewports.smallPhoneWidth}px smoke floor.',
      );
    }
    return const PerformanceAuditCheck(
      id: 'viewport.small_phone',
      title: 'Small-phone viewport supported',
      status: PerformanceCheckStatus.pass,
      detail: '360px small-phone smoke width is the pilot floor.',
    );
  }

  static PerformanceAuditCheck _juniorColumnsCheck(double width) {
    final columns =
        PerformanceLayoutPolicy.subjectColumns(width: width, junior: true);
    final ok = width < PerformanceViewports.tabletWidth ? columns == 2 : true;
    return PerformanceAuditCheck(
      id: 'layout.junior_columns',
      title: 'Junior grid density on phone',
      status: ok ? PerformanceCheckStatus.pass : PerformanceCheckStatus.fail,
      detail: 'Junior subject columns at ${width}px → $columns',
    );
  }

  static PerformanceAuditCheck _seniorColumnsCheck(double width) {
    final columns =
        PerformanceLayoutPolicy.subjectColumns(width: width, junior: false);
    final ok = width < PerformanceViewports.tabletWidth ? columns == 1 : true;
    return PerformanceAuditCheck(
      id: 'layout.senior_columns',
      title: 'Senior list density on phone',
      status: ok ? PerformanceCheckStatus.pass : PerformanceCheckStatus.fail,
      detail: 'Senior subject columns at ${width}px → $columns',
    );
  }

  static PerformanceAuditCheck _textScaleCheck(double textScale) {
    if (textScale > 1.6) {
      return PerformanceAuditCheck(
        id: 'a11y.text_scale',
        title: 'Text scale smoke budget',
        status: PerformanceCheckStatus.fail,
        detail: 'Text scale $textScale exceeds pilot smoke ceiling 1.6.',
      );
    }
    if (textScale >= PerformanceViewports.textScaleSmoke) {
      return PerformanceAuditCheck(
        id: 'a11y.text_scale',
        title: 'Text scale smoke budget',
        status: PerformanceCheckStatus.pass,
        detail:
            'Text scale $textScale meets ${PerformanceViewports.textScaleSmoke} smoke target.',
      );
    }
    return PerformanceAuditCheck(
      id: 'a11y.text_scale',
      title: 'Text scale smoke budget',
      status: PerformanceCheckStatus.warn,
      detail:
          'Text scale $textScale is below ${PerformanceViewports.textScaleSmoke} smoke; still acceptable at 1.0.',
    );
  }

  static PerformanceAuditCheck _denseListCheck(int count) {
    if (count > PerformanceBudgets.denseListWarnCount * 2) {
      return PerformanceAuditCheck(
        id: 'perf.dense_list',
        title: 'Dense list size budget',
        status: PerformanceCheckStatus.fail,
        detail: 'List count $count is too large for unvirtualized smoke.',
      );
    }
    if (count > PerformanceBudgets.denseListWarnCount) {
      return PerformanceAuditCheck(
        id: 'perf.dense_list',
        title: 'Dense list size budget',
        status: PerformanceCheckStatus.warn,
        detail:
            'List count $count exceeds warn threshold ${PerformanceBudgets.denseListWarnCount}.',
      );
    }
    return PerformanceAuditCheck(
      id: 'perf.dense_list',
      title: 'Dense list size budget',
      status: PerformanceCheckStatus.pass,
      detail: 'List count $count within pilot smoke budget.',
    );
  }

  static PerformanceAuditCheck _firstFrameCheck(int? measuredMs) {
    if (measuredMs == null) {
      return PerformanceAuditCheck(
        id: 'perf.first_frame',
        title: 'First-content frame budget',
        status: PerformanceCheckStatus.pass,
        detail:
            'No device measurement in this run; documented budget is ${PerformanceBudgets.firstContentfulFrameMs}ms.',
      );
    }
    if (measuredMs > PerformanceBudgets.firstContentfulFrameMs) {
      return PerformanceAuditCheck(
        id: 'perf.first_frame',
        title: 'First-content frame budget',
        status: PerformanceCheckStatus.fail,
        detail:
            'Measured ${measuredMs}ms exceeds ${PerformanceBudgets.firstContentfulFrameMs}ms budget.',
      );
    }
    return PerformanceAuditCheck(
      id: 'perf.first_frame',
      title: 'First-content frame budget',
      status: PerformanceCheckStatus.pass,
      detail: 'Measured ${measuredMs}ms within budget.',
    );
  }
}
