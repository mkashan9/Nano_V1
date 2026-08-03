import 'package:nano_domain/nano_domain.dart';

/// IND-02 independent access entitlements (fake-first; billing is BIL-01).
abstract class IndependentAccessRepository {
  Future<IndependentEntitlements> loadAccess({required String userId});
}

class FakeIndependentAccessRepository implements IndependentAccessRepository {
  FakeIndependentAccessRepository({
    IndependentEntitlements? seed,
    this.alwaysFail = false,
  }) : _seed = seed ??
            IndependentAccessPolicy.full(
              accessEndsAt: DateTime.utc(2027, 1, 1),
            );

  IndependentEntitlements _seed;
  bool alwaysFail;

  void seed(IndependentEntitlements next) => _seed = next;

  @override
  Future<IndependentEntitlements> loadAccess({required String userId}) async {
    if (alwaysFail) throw StateError('Access unavailable');
    return _seed;
  }
}
