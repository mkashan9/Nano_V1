import 'package:nano_domain/nano_domain.dart';

/// IND-02/03 independent access + plan states (payment capture is BIL-01).
abstract class IndependentAccessRepository {
  Future<IndependentEntitlements> loadAccess({required String userId});

  Future<IndependentPlanSnapshot> loadPlan({required String userId});

  /// Fake-only plan transitions for UI-first review. Never payment proof.
  Future<IndependentPlanSnapshot> applyPlan({
    required String userId,
    required IndependentPlanKind kind,
  });
}

class FakeIndependentAccessRepository implements IndependentAccessRepository {
  FakeIndependentAccessRepository({
    IndependentPlanSnapshot? plan,
    IndependentEntitlements? seed,
    this.alwaysFail = false,
  }) : _plan = plan ?? _planFromLegacySeed(seed);

  IndependentPlanSnapshot _plan;
  bool alwaysFail;

  static IndependentPlanSnapshot _planFromLegacySeed(
    IndependentEntitlements? seed,
  ) {
    if (seed == null) {
      return IndependentPlanSnapshot(
        kind: IndependentPlanKind.trial,
        periodEndsAt: DateTime.now().toUtc().add(const Duration(days: 14)),
      );
    }
    if (seed.isReduced) {
      return const IndependentPlanSnapshot(kind: IndependentPlanKind.expired);
    }
    if (seed.tier == IndependentAccessTier.limited) {
      return IndependentPlanSnapshot(
        kind: IndependentPlanKind.grace,
        periodEndsAt: seed.accessEndsAt ??
            DateTime.now().toUtc().add(const Duration(days: 3)),
      );
    }
    return IndependentPlanSnapshot(
      kind: IndependentPlanKind.paid,
      periodEndsAt: seed.accessEndsAt,
    );
  }

  void seed(IndependentEntitlements next) {
    _plan = _planFromLegacySeed(next);
  }

  void seedPlan(IndependentPlanSnapshot next) => _plan = next;

  @override
  Future<IndependentEntitlements> loadAccess({required String userId}) async {
    if (alwaysFail) throw StateError('Access unavailable');
    return _plan.entitlements;
  }

  @override
  Future<IndependentPlanSnapshot> loadPlan({required String userId}) async {
    if (alwaysFail) throw StateError('Plan unavailable');
    return _plan;
  }

  @override
  Future<IndependentPlanSnapshot> applyPlan({
    required String userId,
    required IndependentPlanKind kind,
  }) async {
    if (alwaysFail) throw StateError('Plan update failed');
    _plan = switch (kind) {
      IndependentPlanKind.free => const IndependentPlanSnapshot(
          kind: IndependentPlanKind.free,
        ),
      IndependentPlanKind.trial => IndependentPlanMath.startTrial(
          const IndependentPlanSnapshot(kind: IndependentPlanKind.free),
        ),
      IndependentPlanKind.paid => IndependentPlanMath.markPaid(_plan),
      IndependentPlanKind.grace => IndependentPlanMath.enterGrace(_plan),
      IndependentPlanKind.expired => IndependentPlanMath.expire(_plan),
    };
    return _plan;
  }
}
