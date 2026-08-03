import 'package:nano_domain/nano_domain.dart';

/// QA-02 performance / small-device audit report.
abstract class PerformanceAuditRepository {
  Future<PerformanceAuditReport> loadReport({
    double width = PerformanceViewports.smallPhoneWidth,
    double textScale = PerformanceViewports.textScaleSmoke,
    int denseListCount = 12,
    int? measuredFirstFrameMs,
  });
}

class FakePerformanceAuditRepository implements PerformanceAuditRepository {
  FakePerformanceAuditRepository({this.alwaysFail = false});

  bool alwaysFail;

  @override
  Future<PerformanceAuditReport> loadReport({
    double width = PerformanceViewports.smallPhoneWidth,
    double textScale = PerformanceViewports.textScaleSmoke,
    int denseListCount = 12,
    int? measuredFirstFrameMs,
  }) async {
    if (alwaysFail) throw StateError('Performance audit unavailable');
    return PerformanceAuditPolicy.evaluate(
      width: width,
      textScale: textScale,
      denseListCount: denseListCount,
      measuredFirstFrameMs: measuredFirstFrameMs,
    );
  }
}
