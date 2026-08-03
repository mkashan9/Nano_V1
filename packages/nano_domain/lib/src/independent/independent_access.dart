/// IND-02 independent access entitlements (billing/payment is IND-03 / BIL-01).

enum IndependentAccessTier {
  /// Full learning, games, and allowed social features.
  full,

  /// Still usable, but access is ending soon — show a calm warning.
  limited,

  /// Reduced experience: learning stays; games/communities stay closed.
  restricted,
}

enum IndependentFeature {
  learning,
  games,
  communities,
  quizzes,
}

class IndependentEntitlements {
  const IndependentEntitlements({
    required this.tier,
    required this.allowedFeatures,
    this.accessEndsAt,
    this.planLabel = 'Independent',
  });

  final IndependentAccessTier tier;
  final Set<IndependentFeature> allowedFeatures;
  final DateTime? accessEndsAt;
  final String planLabel;

  bool allows(IndependentFeature feature) =>
      IndependentAccessPolicy.allows(this, feature);

  bool get showsAccessWarning =>
      IndependentAccessPolicy.showsAccessWarning(this);

  bool get isReduced => tier == IndependentAccessTier.restricted;

  factory IndependentEntitlements.fromJson(Map<String, dynamic> json) {
    final tierRaw = '${json['tier'] ?? 'full'}';
    final tier = switch (tierRaw) {
      'limited' => IndependentAccessTier.limited,
      'restricted' => IndependentAccessTier.restricted,
      _ => IndependentAccessTier.full,
    };
    final rawFeatures = json['allowed_features'];
    final features = <IndependentFeature>{};
    if (rawFeatures is List) {
      for (final item in rawFeatures) {
        final parsed = switch ('$item') {
          'games' => IndependentFeature.games,
          'communities' => IndependentFeature.communities,
          'quizzes' => IndependentFeature.quizzes,
          'learning' => IndependentFeature.learning,
          _ => null,
        };
        if (parsed != null) features.add(parsed);
      }
    }
    return IndependentEntitlements(
      tier: tier,
      allowedFeatures: features.isEmpty
          ? IndependentAccessPolicy.featuresFor(tier)
          : features,
      accessEndsAt: json['access_ends_at'] == null
          ? null
          : DateTime.tryParse('${json['access_ends_at']}'),
      planLabel: json['plan_label'] as String? ?? 'Independent',
    );
  }
}

/// Server-shaped rules mirrored on the client for UI-first gates.
/// Live RLS / Edge checks remain authoritative when billing ships.
abstract final class IndependentAccessPolicy {
  static Set<IndependentFeature> featuresFor(IndependentAccessTier tier) =>
      switch (tier) {
        IndependentAccessTier.full || IndependentAccessTier.limited => {
            IndependentFeature.learning,
            IndependentFeature.games,
            IndependentFeature.communities,
            IndependentFeature.quizzes,
          },
        IndependentAccessTier.restricted => {
            IndependentFeature.learning,
            IndependentFeature.quizzes,
          },
      };

  static IndependentEntitlements full({DateTime? accessEndsAt}) =>
      IndependentEntitlements(
        tier: IndependentAccessTier.full,
        allowedFeatures: featuresFor(IndependentAccessTier.full),
        accessEndsAt: accessEndsAt,
      );

  static IndependentEntitlements limited({required DateTime accessEndsAt}) =>
      IndependentEntitlements(
        tier: IndependentAccessTier.limited,
        allowedFeatures: featuresFor(IndependentAccessTier.limited),
        accessEndsAt: accessEndsAt,
        planLabel: 'Independent · ending soon',
      );

  static IndependentEntitlements restricted() => IndependentEntitlements(
        tier: IndependentAccessTier.restricted,
        allowedFeatures: featuresFor(IndependentAccessTier.restricted),
        planLabel: 'Independent · reduced access',
      );

  static bool allows(
    IndependentEntitlements entitlements,
    IndependentFeature feature,
  ) {
    // Learning never fully disappears — handbook: useful reduced-access.
    if (feature == IndependentFeature.learning) return true;
    if (entitlements.tier == IndependentAccessTier.restricted &&
        (feature == IndependentFeature.games ||
            feature == IndependentFeature.communities)) {
      return false;
    }
    return entitlements.allowedFeatures.contains(feature);
  }

  static bool showsAccessWarning(IndependentEntitlements entitlements) {
    if (entitlements.tier == IndependentAccessTier.limited) return true;
    if (entitlements.tier == IndependentAccessTier.restricted) return true;
    final ends = entitlements.accessEndsAt;
    if (ends == null) return false;
    final remaining = ends.toUtc().difference(DateTime.now().toUtc());
    return remaining.inDays <= 7 && !remaining.isNegative;
  }
}
