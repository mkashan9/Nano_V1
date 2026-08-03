import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('IndependentAccessPolicy', () {
    test('full access allows learning games communities', () {
      final access = IndependentAccessPolicy.full();
      expect(access.allows(IndependentFeature.learning), isTrue);
      expect(access.allows(IndependentFeature.games), isTrue);
      expect(access.allows(IndependentFeature.communities), isTrue);
      expect(access.showsAccessWarning, isFalse);
    });

    test('limited shows warning and keeps games open', () {
      final access = IndependentAccessPolicy.limited(
        accessEndsAt: DateTime.now().toUtc().add(const Duration(days: 2)),
      );
      expect(access.tier, IndependentAccessTier.limited);
      expect(access.showsAccessWarning, isTrue);
      expect(access.allows(IndependentFeature.games), isTrue);
    });

    test('restricted keeps learning and closes games', () {
      final access = IndependentAccessPolicy.restricted();
      expect(access.isReduced, isTrue);
      expect(access.allows(IndependentFeature.learning), isTrue);
      expect(access.allows(IndependentFeature.games), isFalse);
      expect(access.allows(IndependentFeature.communities), isFalse);
      expect(access.showsAccessWarning, isTrue);
    });

    test('fromJson round-trips restricted features', () {
      final parsed = IndependentEntitlements.fromJson({
        'tier': 'restricted',
        'allowed_features': ['learning', 'quizzes'],
        'plan_label': 'Reduced',
      });
      expect(parsed.tier, IndependentAccessTier.restricted);
      expect(parsed.allows(IndependentFeature.games), isFalse);
      expect(parsed.planLabel, 'Reduced');
    });
  });
}
