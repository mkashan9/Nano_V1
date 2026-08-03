import 'independent_access.dart';

/// IND-03 trial / free / paid plan states (payment capture is BIL-01).

enum IndependentPlanKind {
  /// No paid period; full learning with a calm free label.
  free,

  /// Time-boxed full access.
  trial,

  /// Paid period in good standing.
  paid,

  /// Short post-expiry window — still usable, ending soon.
  grace,

  /// Expired — reduced access via IND-02 restricted tier.
  expired,
}

class IndependentPlanSnapshot {
  const IndependentPlanSnapshot({
    required this.kind,
    this.periodEndsAt,
    this.trialDays = 14,
  });

  final IndependentPlanKind kind;
  final DateTime? periodEndsAt;
  final int trialDays;

  int? get daysRemaining {
    final ends = periodEndsAt;
    if (ends == null) return null;
    final remaining = ends.toUtc().difference(DateTime.now().toUtc());
    if (remaining.isNegative) return 0;
    return remaining.inDays;
  }

  bool get canStartTrial => kind == IndependentPlanKind.free;

  IndependentEntitlements get entitlements =>
      IndependentPlanMath.toEntitlements(this);

  IndependentPlanSnapshot copyWith({
    IndependentPlanKind? kind,
    DateTime? periodEndsAt,
    bool clearPeriodEndsAt = false,
    int? trialDays,
  }) {
    return IndependentPlanSnapshot(
      kind: kind ?? this.kind,
      periodEndsAt:
          clearPeriodEndsAt ? null : (periodEndsAt ?? this.periodEndsAt),
      trialDays: trialDays ?? this.trialDays,
    );
  }

  factory IndependentPlanSnapshot.fromJson(Map<String, dynamic> json) {
    final kind = switch ('${json['kind'] ?? 'free'}') {
      'trial' => IndependentPlanKind.trial,
      'paid' => IndependentPlanKind.paid,
      'grace' => IndependentPlanKind.grace,
      'expired' => IndependentPlanKind.expired,
      _ => IndependentPlanKind.free,
    };
    return IndependentPlanSnapshot(
      kind: kind,
      periodEndsAt: json['period_ends_at'] == null
          ? null
          : DateTime.tryParse('${json['period_ends_at']}'),
      trialDays: (json['trial_days'] as num?)?.toInt() ?? 14,
    );
  }
}

/// Maps plan states onto IND-02 entitlements without payment receipts.
abstract final class IndependentPlanMath {
  static IndependentEntitlements toEntitlements(IndependentPlanSnapshot plan) {
    final ends = plan.periodEndsAt;
    return switch (plan.kind) {
      IndependentPlanKind.free => IndependentEntitlements(
          tier: IndependentAccessTier.full,
          allowedFeatures:
              IndependentAccessPolicy.featuresFor(IndependentAccessTier.full),
          planLabel: 'Free',
        ),
      IndependentPlanKind.trial => IndependentAccessPolicy.full(
          accessEndsAt: ends,
        ).copyWithLabel('Trial'),
      IndependentPlanKind.paid => IndependentAccessPolicy.full(
          accessEndsAt: ends,
        ).copyWithLabel('Paid'),
      IndependentPlanKind.grace => IndependentAccessPolicy.limited(
          accessEndsAt: ends ??
              DateTime.now().toUtc().add(const Duration(days: 3)),
        ).copyWithLabel('Grace'),
      IndependentPlanKind.expired =>
        IndependentAccessPolicy.restricted().copyWithLabel('Expired'),
    };
  }

  /// Fake-only transitions — never treat as payment proof (BIL-01).
  static IndependentPlanSnapshot startTrial(
    IndependentPlanSnapshot current, {
    DateTime? now,
    int? days,
  }) {
    if (!current.canStartTrial) return current;
    final start = now ?? DateTime.now().toUtc();
    final length = days ?? current.trialDays;
    return IndependentPlanSnapshot(
      kind: IndependentPlanKind.trial,
      periodEndsAt: start.add(Duration(days: length)),
      trialDays: length,
    );
  }

  static IndependentPlanSnapshot markPaid(
    IndependentPlanSnapshot current, {
    DateTime? now,
    int days = 30,
  }) {
    final start = now ?? DateTime.now().toUtc();
    return IndependentPlanSnapshot(
      kind: IndependentPlanKind.paid,
      periodEndsAt: start.add(Duration(days: days)),
      trialDays: current.trialDays,
    );
  }

  static IndependentPlanSnapshot enterGrace(
    IndependentPlanSnapshot current, {
    DateTime? now,
    int days = 3,
  }) {
    final start = now ?? DateTime.now().toUtc();
    return IndependentPlanSnapshot(
      kind: IndependentPlanKind.grace,
      periodEndsAt: start.add(Duration(days: days)),
      trialDays: current.trialDays,
    );
  }

  static IndependentPlanSnapshot expire(IndependentPlanSnapshot current) {
    return IndependentPlanSnapshot(
      kind: IndependentPlanKind.expired,
      trialDays: current.trialDays,
    );
  }
}

extension on IndependentEntitlements {
  IndependentEntitlements copyWithLabel(String label) {
    return IndependentEntitlements(
      tier: tier,
      allowedFeatures: allowedFeatures,
      accessEndsAt: accessEndsAt,
      planLabel: label,
    );
  }
}
