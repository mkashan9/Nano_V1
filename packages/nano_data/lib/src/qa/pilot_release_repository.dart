import 'package:nano_domain/nano_domain.dart';

/// QA-06 pilot release readiness report.
abstract class PilotReleaseRepository {
  Future<PilotReleaseReport> loadReport({
    PilotReleaseGates gates = PilotReleaseGates.pilotReady,
    EnvironmentConfig? config,
  });
}

class FakePilotReleaseRepository implements PilotReleaseRepository {
  FakePilotReleaseRepository({this.alwaysFail = false});

  bool alwaysFail;

  @override
  Future<PilotReleaseReport> loadReport({
    PilotReleaseGates gates = PilotReleaseGates.pilotReady,
    EnvironmentConfig? config,
  }) async {
    if (alwaysFail) throw StateError('Pilot release report unavailable');
    return PilotReleasePolicy.evaluate(gates: gates, config: config);
  }
}
