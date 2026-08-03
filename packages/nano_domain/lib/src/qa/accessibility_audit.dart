import '../accessibility/accessibility_preferences.dart';

/// QA-04 accessibility smoke checklist (builds on FND-07 / handbook 8.5).

enum AccessibilityCheckStatus { pass, warn, fail }

class AccessibilityAuditCheck {
  const AccessibilityAuditCheck({
    required this.id,
    required this.title,
    required this.status,
    required this.detail,
  });

  final String id;
  final String title;
  final AccessibilityCheckStatus status;
  final String detail;

  bool get passed => status != AccessibilityCheckStatus.fail;
}

class AccessibilityAuditReport {
  const AccessibilityAuditReport({
    required this.checks,
    required this.generatedAt,
  });

  final List<AccessibilityAuditCheck> checks;
  final DateTime generatedAt;

  bool get allPassed => checks.every((check) => check.passed);
  int get failCount => checks
      .where((check) => check.status == AccessibilityCheckStatus.fail)
      .length;
}

/// Smoke budgets aligned with FND-07 prefs UI and handbook 8.5.
abstract final class AccessibilityAuditBudgets {
  /// Pilot text-scale smoke (same target as QA-02 small-device smoke).
  static const textScaleSmoke = 1.3;

  /// Prefs slider floor / ceiling on Accessibility settings.
  static const textScaleMin = 0.85;
  static const textScaleMax = 1.6;

  /// WCAG-aligned minimum tap target (dp). Theme floors must stay ≥ this.
  static const minTapTargetDp = 44.0;

  /// Documented theme floors (must not import design_system into domain).
  static const juniorMinTapTargetDp = 56.0;
  static const seniorMinTapTargetDp = 48.0;
  static const adminMinTapTargetDp = 44.0;
}

abstract final class AccessibilityAuditPolicy {
  static AccessibilityAuditReport evaluate({
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    double textScale = AccessibilityAuditBudgets.textScaleSmoke,
    bool controlsHaveSemanticLabels = true,
    bool statusUsesNonColorCue = true,
    bool brandingPreservesContrast = true,
    DateTime? now,
  }) {
    final checks = <AccessibilityAuditCheck>[
      _textScale(textScale),
      _semanticLabels(controlsHaveSemanticLabels),
      _captions(preferences),
      _colorNotSole(statusUsesNonColorCue),
      _reducedMotion(preferences),
      _touchTargets(),
      _brandingContrast(brandingPreservesContrast),
      _bidiPointer(),
    ];
    return AccessibilityAuditReport(
      checks: checks,
      generatedAt: now ?? DateTime.now().toUtc(),
    );
  }

  static AccessibilityAuditCheck _textScale(double textScale) {
    final inRange = textScale >= AccessibilityAuditBudgets.textScaleMin &&
        textScale <= AccessibilityAuditBudgets.textScaleMax;
    if (!inRange) {
      return AccessibilityAuditCheck(
        id: 'a11y.text_scale',
        title: 'Text scale reflow budget',
        status: AccessibilityCheckStatus.fail,
        detail:
            'textScale $textScale is outside ${AccessibilityAuditBudgets.textScaleMin}–${AccessibilityAuditBudgets.textScaleMax}.',
      );
    }
    if (textScale < AccessibilityAuditBudgets.textScaleSmoke) {
      return AccessibilityAuditCheck(
        id: 'a11y.text_scale',
        title: 'Text scale reflow budget',
        status: AccessibilityCheckStatus.warn,
        detail:
            'textScale $textScale is in range; pilot smoke prefers ${AccessibilityAuditBudgets.textScaleSmoke}.',
      );
    }
    return AccessibilityAuditCheck(
      id: 'a11y.text_scale',
      title: 'Text scale reflow budget',
      status: AccessibilityCheckStatus.pass,
      detail:
          'textScale $textScale meets pilot smoke (${AccessibilityAuditBudgets.textScaleSmoke}) and prefs range.',
    );
  }

  static AccessibilityAuditCheck _semanticLabels(bool labeled) {
    return AccessibilityAuditCheck(
      id: 'a11y.semantics',
      title: 'Controls have semantic labels',
      status:
          labeled ? AccessibilityCheckStatus.pass : AccessibilityCheckStatus.fail,
      detail: labeled
          ? 'Interactive controls expose Semantics labels / NanoAccessibleTarget.'
          : 'Unlabeled controls break focus order and screen readers.',
    );
  }

  static AccessibilityAuditCheck _captions(AccessibilityPreferences prefs) {
    return AccessibilityAuditCheck(
      id: 'a11y.captions',
      title: 'Captions available for speech',
      status: prefs.captionsEnabled
          ? AccessibilityCheckStatus.pass
          : AccessibilityCheckStatus.warn,
      detail: prefs.captionsEnabled
          ? 'Captions preference is on for learning / companion speech.'
          : 'Captions are off — media with speech should still offer captions.',
    );
  }

  static AccessibilityAuditCheck _colorNotSole(bool nonColorCue) {
    return AccessibilityAuditCheck(
      id: 'a11y.color_not_sole',
      title: 'Color is not the only status cue',
      status: nonColorCue
          ? AccessibilityCheckStatus.pass
          : AccessibilityCheckStatus.fail,
      detail: nonColorCue
          ? 'Attendance / correctness / publish state use icon or text with color.'
          : 'Status relies on color alone — fails handbook 8.5.',
    );
  }

  static AccessibilityAuditCheck _reducedMotion(
    AccessibilityPreferences prefs,
  ) {
    final reduced = prefs.effectiveReducedMotion;
    return AccessibilityAuditCheck(
      id: 'a11y.reduced_motion',
      title: 'Reduced motion path',
      status: AccessibilityCheckStatus.pass,
      detail: reduced
          ? 'effectiveReducedMotion is on — prefer fades / static changes.'
          : 'Reduced motion toggle and Classroom Mode are available (FND-07).',
    );
  }

  static AccessibilityAuditCheck _touchTargets() {
    final floors = [
      AccessibilityAuditBudgets.juniorMinTapTargetDp,
      AccessibilityAuditBudgets.seniorMinTapTargetDp,
      AccessibilityAuditBudgets.adminMinTapTargetDp,
    ];
    final ok = floors.every(
      (floor) => floor >= AccessibilityAuditBudgets.minTapTargetDp,
    );
    return AccessibilityAuditCheck(
      id: 'a11y.touch_targets',
      title: 'Minimum touch targets',
      status: ok
          ? AccessibilityCheckStatus.pass
          : AccessibilityCheckStatus.fail,
      detail: ok
          ? 'Theme floors (junior ${AccessibilityAuditBudgets.juniorMinTapTargetDp.toInt()} / '
              'senior ${AccessibilityAuditBudgets.seniorMinTapTargetDp.toInt()} / '
              'admin ${AccessibilityAuditBudgets.adminMinTapTargetDp.toInt()}) '
              '≥ ${AccessibilityAuditBudgets.minTapTargetDp.toInt()}dp.'
          : 'A theme floor is below ${AccessibilityAuditBudgets.minTapTargetDp.toInt()}dp.',
    );
  }

  static AccessibilityAuditCheck _brandingContrast(bool preserved) {
    return AccessibilityAuditCheck(
      id: 'a11y.branding_contrast',
      title: 'Branding preserves contrast',
      status: preserved
          ? AccessibilityCheckStatus.pass
          : AccessibilityCheckStatus.fail,
      detail: preserved
          ? 'School branding fills approved slots only — safety colors stay.'
          : 'Branding overrode contrast-critical / safety colors.',
    );
  }

  static AccessibilityAuditCheck _bidiPointer() {
    return const AccessibilityAuditCheck(
      id: 'a11y.bidi_pointer',
      title: 'EN / Urdu layout overflow',
      status: AccessibilityCheckStatus.pass,
      detail:
          'EN+Urdu overflow / reading direction full audit is owned by QA-05.',
    );
  }
}
