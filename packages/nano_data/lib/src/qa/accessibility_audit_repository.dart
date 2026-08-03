import 'package:nano_domain/nano_domain.dart';

/// QA-04 accessibility audit report.
abstract class AccessibilityAuditRepository {
  Future<AccessibilityAuditReport> loadReport({
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    double textScale = AccessibilityAuditBudgets.textScaleSmoke,
    bool controlsHaveSemanticLabels = true,
    bool statusUsesNonColorCue = true,
    bool brandingPreservesContrast = true,
  });
}

class FakeAccessibilityAuditRepository implements AccessibilityAuditRepository {
  FakeAccessibilityAuditRepository({this.alwaysFail = false});

  bool alwaysFail;

  @override
  Future<AccessibilityAuditReport> loadReport({
    AccessibilityPreferences preferences = AccessibilityPreferences.defaults,
    double textScale = AccessibilityAuditBudgets.textScaleSmoke,
    bool controlsHaveSemanticLabels = true,
    bool statusUsesNonColorCue = true,
    bool brandingPreservesContrast = true,
  }) async {
    if (alwaysFail) throw StateError('Accessibility audit unavailable');
    return AccessibilityAuditPolicy.evaluate(
      preferences: preferences,
      textScale: textScale,
      controlsHaveSemanticLabels: controlsHaveSemanticLabels,
      statusUsesNonColorCue: statusUsesNonColorCue,
      brandingPreservesContrast: brandingPreservesContrast,
    );
  }
}
