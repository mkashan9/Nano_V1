import 'generated_asset.dart';

/// Which budget a limit belongs to (MED-02).
enum GenerationQuotaScope {
  /// The whole platform, every feature and every school.
  platform,

  /// One part of the product, for example the companion.
  feature,

  /// One school, when a request was made on its behalf.
  school;

  static GenerationQuotaScope fromName(String value) =>
      GenerationQuotaScope.values.firstWhere(
        (scope) => scope.name == value,
        orElse: () => GenerationQuotaScope.platform,
      );
}

/// One day's allowance and what has been spent against it (MED-02).
///
/// A curator sees these before asking for more work. Learners never do: the
/// server returns no rows to them, so an empty list is the normal answer rather
/// than an error to handle.
class GenerationBudget {
  const GenerationBudget({
    required this.scope,
    required this.scopeKey,
    required this.kind,
    required this.maxRequestsPerDay,
    required this.requestsUsed,
    required this.maxCostMicrosPerDay,
    required this.costMicrosUsed,
  });

  final GenerationQuotaScope scope;

  /// Empty for the platform scope, otherwise the feature name or school id.
  final String scopeKey;

  /// Null when the budget covers every kind together.
  final GeneratedAssetKind? kind;

  final int maxRequestsPerDay;
  final int requestsUsed;
  final int maxCostMicrosPerDay;
  final int costMicrosUsed;

  int get requestsRemaining =>
      (maxRequestsPerDay - requestsUsed).clamp(0, maxRequestsPerDay);

  int get costMicrosRemaining =>
      (maxCostMicrosPerDay - costMicrosUsed).clamp(0, maxCostMicrosPerDay);

  /// True when this budget would refuse the next request. Either limit is enough
  /// to stop one, which is why this is not a single ratio.
  bool get isExhausted =>
      requestsUsed >= maxRequestsPerDay || costMicrosUsed >= maxCostMicrosPerDay;

  /// A label a curator can read: `platform`, `companion`, or a school id.
  String get label => scopeKey.isEmpty ? scope.name : scopeKey;

  factory GenerationBudget.fromRow(Map<String, dynamic> row) {
    final rawKind = row['kind'] as String? ?? 'all';
    return GenerationBudget(
      scope: GenerationQuotaScope.fromName(row['scope'] as String? ?? 'platform'),
      scopeKey: row['scope_key'] as String? ?? '',
      // The server says 'all' rather than null, because a text column is easier
      // to read in a dashboard than an absent one.
      kind: rawKind == 'all' ? null : GeneratedAssetKind.fromName(rawKind),
      maxRequestsPerDay: (row['max_requests_per_day'] as num?)?.toInt() ?? 0,
      requestsUsed: (row['requests_used'] as num?)?.toInt() ?? 0,
      maxCostMicrosPerDay: (row['max_cost_micros_per_day'] as num?)?.toInt() ?? 0,
      costMicrosUsed: (row['cost_micros_used'] as num?)?.toInt() ?? 0,
    );
  }
}

/// The day's allowance is spent (MED-02).
///
/// Worth its own type because it is the one generation failure that is not a
/// fault: nothing is broken, the answer is simply "not today". A caller should
/// say so plainly instead of offering a retry that cannot succeed.
class GenerationQuotaExceeded implements Exception {
  const GenerationQuotaExceeded(this.message);

  final String message;

  @override
  String toString() => 'GenerationQuotaExceeded: $message';
}
