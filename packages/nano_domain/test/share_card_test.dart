import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('privacySafeFirstName keeps only the first token', () {
    expect(ShareCard.privacySafeFirstName('Ali Alpha'), 'Ali');
    expect(ShareCard.privacySafeFirstName('  Sara  Khan '), 'Sara');
    expect(ShareCard.privacySafeFirstName(''), 'Learner');
  });

  test('achievement card never embeds a full school-linked name', () {
    final card = ShareCard.achievement(
      displayName: 'Ali Alpha',
      titleEn: 'Quiz Rookie',
      titleUr: 'کوئز نوآموز',
      descriptionEn: 'Pass your first quiz.',
      slug: 'quiz_rookie',
    );
    expect(card.firstName, 'Ali');
    expect(card.shareTextEn, contains('Ali earned Quiz Rookie'));
    expect(card.shareTextEn, isNot(contains('Alpha')));
    expect(card.shareTextEn.toLowerCase(), isNot(contains('email')));
  });

  test('quiz score card omits topic and school fields', () {
    final card = ShareCard.quizScore(
      displayName: 'Bina Beta',
      scorePercent: 90,
      passed: true,
    );
    expect(card.scorePercent, 90);
    expect(card.shareTextEn, contains('Bina scored 90%'));
    expect(card.shareTextEn.toLowerCase(), isNot(contains('school')));
    expect(card.shareTextEn.toLowerCase(), isNot(contains('@')));
  });

  test('fromRow rejects payloads with private keys', () {
    expect(
      () => ShareCard.fromRow({
        'kind': 'achievement',
        'first_name': 'Ali',
        'headline_en': 'x',
        'headline_ur': 'x',
        'body_en': 'x',
        'body_ur': 'x',
        'share_text_en': 'x',
        'share_text_ur': 'x',
        'email': 'ali@example.dev',
      }),
      throwsStateError,
    );
  });

  test('featured pin budget is three', () {
    expect(kMaxFeaturedAchievements, 3);
  });
}
