import 'package:nano_domain/nano_domain.dart';

/// QA-01 security hardening report (client-side gates + checklist).
abstract class SecurityHardeningRepository {
  Future<SecurityHardeningReport> loadReport({
    required EnvironmentConfig config,
    SessionPrincipal? principal,
  });
}

class FakeSecurityHardeningRepository implements SecurityHardeningRepository {
  FakeSecurityHardeningRepository({this.alwaysFail = false});

  bool alwaysFail;

  @override
  Future<SecurityHardeningReport> loadReport({
    required EnvironmentConfig config,
    SessionPrincipal? principal,
  }) async {
    if (alwaysFail) throw StateError('Hardening report unavailable');
    return SecurityHardeningPolicy.evaluate(
      config: config,
      principal: principal,
    );
  }
}
