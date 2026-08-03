import 'package:nano_domain/nano_domain.dart';

/// QA-03 offline / poor-network audit report.
abstract class OfflineNetworkAuditRepository {
  Future<OfflineNetworkAuditReport> loadReport({
    NetworkQuality quality = NetworkQuality.offline,
    bool cacheHit = true,
    bool conflictSurfaced = true,
    bool operationIdsUnique = true,
    int? latencyMs,
  });
}

class FakeOfflineNetworkAuditRepository
    implements OfflineNetworkAuditRepository {
  FakeOfflineNetworkAuditRepository({this.alwaysFail = false});

  bool alwaysFail;

  @override
  Future<OfflineNetworkAuditReport> loadReport({
    NetworkQuality quality = NetworkQuality.offline,
    bool cacheHit = true,
    bool conflictSurfaced = true,
    bool operationIdsUnique = true,
    int? latencyMs,
  }) async {
    if (alwaysFail) throw StateError('Offline network audit unavailable');
    final resolved = latencyMs == null
        ? quality
        : NetworkQualityPolicy.fromLatencyMs(latencyMs);
    return OfflineNetworkAuditPolicy.evaluate(
      quality: resolved,
      cacheHit: cacheHit,
      conflictSurfaced: conflictSurfaced,
      operationIdsUnique: operationIdsUnique,
    );
  }
}
