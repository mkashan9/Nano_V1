import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('IndependentPlanMath', () {
    test('maps free trial paid grace expired onto entitlements', () {
      expect(
        const IndependentPlanSnapshot(kind: IndependentPlanKind.free)
            .entitlements
            .planLabel,
        'Free',
      );
      expect(
        IndependentPlanSnapshot(
          kind: IndependentPlanKind.trial,
          periodEndsAt: DateTime.utc(2026, 9, 1),
        ).entitlements.allows(IndependentFeature.games),
        isTrue,
      );
      expect(
        const IndependentPlanSnapshot(kind: IndependentPlanKind.expired)
            .entitlements
            .isReduced,
        isTrue,
      );
      expect(
        IndependentPlanSnapshot(
          kind: IndependentPlanKind.grace,
          periodEndsAt: DateTime.utc(2026, 8, 10),
        ).entitlements.showsAccessWarning,
        isTrue,
      );
    });

    test('startTrial only from free', () {
      final started = IndependentPlanMath.startTrial(
        const IndependentPlanSnapshot(kind: IndependentPlanKind.free),
        now: DateTime.utc(2026, 8, 3),
        days: 14,
      );
      expect(started.kind, IndependentPlanKind.trial);
      expect(started.periodEndsAt, DateTime.utc(2026, 8, 17));

      final ignored = IndependentPlanMath.startTrial(
        IndependentPlanSnapshot(
          kind: IndependentPlanKind.paid,
          periodEndsAt: DateTime.utc(2026, 9, 1),
        ),
      );
      expect(ignored.kind, IndependentPlanKind.paid);
    });

    test('markPaid and expire transitions', () {
      final paid = IndependentPlanMath.markPaid(
        const IndependentPlanSnapshot(kind: IndependentPlanKind.trial),
        now: DateTime.utc(2026, 8, 3),
        days: 30,
      );
      expect(paid.kind, IndependentPlanKind.paid);
      expect(paid.periodEndsAt, DateTime.utc(2026, 9, 2));

      final expired = IndependentPlanMath.expire(paid);
      expect(expired.kind, IndependentPlanKind.expired);
      expect(expired.entitlements.allows(IndependentFeature.games), isFalse);
    });
  });
}
