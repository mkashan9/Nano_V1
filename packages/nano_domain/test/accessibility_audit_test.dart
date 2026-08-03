import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('smoke report passes at textScale 1.3', () {
    final report = AccessibilityAuditPolicy.evaluate(
      textScale: AccessibilityAuditBudgets.textScaleSmoke,
    );
    expect(report.allPassed, isTrue);
    expect(
      report.checks.any((check) => check.id == 'a11y.text_scale'),
      isTrue,
    );
  });

  test('out-of-range text scale fails', () {
    final report = AccessibilityAuditPolicy.evaluate(textScale: 2.5);
    expect(report.allPassed, isFalse);
    expect(
      report.checks
          .firstWhere((check) => check.id == 'a11y.text_scale')
          .status,
      AccessibilityCheckStatus.fail,
    );
  });

  test('unlabeled controls fail semantics check', () {
    final report = AccessibilityAuditPolicy.evaluate(
      controlsHaveSemanticLabels: false,
    );
    expect(
      report.checks.firstWhere((check) => check.id == 'a11y.semantics').status,
      AccessibilityCheckStatus.fail,
    );
  });

  test('theme tap floors meet minimum budget', () {
    expect(
      AccessibilityAuditBudgets.juniorMinTapTargetDp,
      greaterThanOrEqualTo(AccessibilityAuditBudgets.minTapTargetDp),
    );
    expect(
      AccessibilityAuditBudgets.seniorMinTapTargetDp,
      greaterThanOrEqualTo(AccessibilityAuditBudgets.minTapTargetDp),
    );
    expect(
      AccessibilityAuditBudgets.adminMinTapTargetDp,
      greaterThanOrEqualTo(AccessibilityAuditBudgets.minTapTargetDp),
    );
  });
}
