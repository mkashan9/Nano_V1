import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('SocialSharePlan builds WhatsApp uri without private fields', () {
    final card = ShareCard.achievement(
      displayName: 'Ali Alpha',
      titleEn: 'First quiz',
      titleUr: 'پہلا کوئز',
    );
    final plan = SocialSharePlan.of(card, ShareTarget.whatsApp, urdu: false);
    expect(plan.whatsAppUri, isNotNull);
    expect(plan.whatsAppUri!.host, 'wa.me');
    expect(plan.shareText.toLowerCase(), isNot(contains('school')));
    expect(plan.shareText, contains('Ali'));
  });

  test('Communities target is deferred', () {
    final card = ShareCard.quizScore(
      displayName: 'sara',
      scorePercent: 90,
      passed: true,
    );
    final plan =
        SocialSharePlan.of(card, ShareTarget.communities, urdu: false);
    expect(plan.isDeferred, isTrue);
    expect(plan.whatsAppUri, isNull);
  });
}
