import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('small phone layout columns match junior/senior density', () {
    expect(
      PerformanceLayoutPolicy.subjectColumns(
        width: PerformanceViewports.smallPhoneWidth,
        junior: true,
      ),
      2,
    );
    expect(
      PerformanceLayoutPolicy.subjectColumns(
        width: PerformanceViewports.smallPhoneWidth,
        junior: false,
      ),
      1,
    );
  });

  test('smoke report passes at 360px and 1.3 text scale', () {
    final report = PerformanceAuditPolicy.evaluate(
      width: PerformanceViewports.smallPhoneWidth,
      textScale: PerformanceViewports.textScaleSmoke,
      denseListCount: 12,
    );
    expect(report.allPassed, isTrue);
    expect(
      report.checks.any((check) => check.id == 'viewport.small_phone'),
      isTrue,
    );
  });

  test('oversized dense list fails budget', () {
    final report = PerformanceAuditPolicy.evaluate(
      denseListCount: PerformanceBudgets.denseListWarnCount * 3,
    );
    expect(report.allPassed, isFalse);
    expect(
      report.checks
          .firstWhere((check) => check.id == 'perf.dense_list')
          .status,
      PerformanceCheckStatus.fail,
    );
  });

  test('slow first frame fails budget when measured', () {
    final report = PerformanceAuditPolicy.evaluate(
      measuredFirstFrameMs: PerformanceBudgets.firstContentfulFrameMs + 500,
    );
    expect(
      report.checks
          .firstWhere((check) => check.id == 'perf.first_frame')
          .status,
      PerformanceCheckStatus.fail,
    );
  });
}
