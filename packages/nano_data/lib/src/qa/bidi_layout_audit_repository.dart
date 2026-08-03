import 'package:nano_domain/nano_domain.dart';

/// QA-05 Urdu / bidirectional layout audit report.
abstract class BidiLayoutAuditRepository {
  Future<BidiLayoutAuditReport> loadReport({
    NanoAppLocale locale = NanoAppLocale.ur,
    double width = BidiLayoutBudgets.smallPhoneWidth,
    double textScale = BidiLayoutBudgets.textScaleSmoke,
    bool sampleCopyPresent = true,
    bool overflowDetected = false,
    bool mixedScriptOk = true,
  });
}

class FakeBidiLayoutAuditRepository implements BidiLayoutAuditRepository {
  FakeBidiLayoutAuditRepository({this.alwaysFail = false});

  bool alwaysFail;

  @override
  Future<BidiLayoutAuditReport> loadReport({
    NanoAppLocale locale = NanoAppLocale.ur,
    double width = BidiLayoutBudgets.smallPhoneWidth,
    double textScale = BidiLayoutBudgets.textScaleSmoke,
    bool sampleCopyPresent = true,
    bool overflowDetected = false,
    bool mixedScriptOk = true,
  }) async {
    if (alwaysFail) throw StateError('Bidi layout audit unavailable');
    return BidiLayoutAuditPolicy.evaluate(
      locale: locale,
      width: width,
      textScale: textScale,
      sampleCopyPresent: sampleCopyPresent,
      overflowDetected: overflowDetected,
      mixedScriptOk: mixedScriptOk,
    );
  }
}
