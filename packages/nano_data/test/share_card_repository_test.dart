import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

AchievementAward _award(String id, String slug, String title) {
  return AchievementAward(
    awardId: id,
    slug: slug,
    kind: AchievementKind.achievement,
    titleEn: title,
    titleUr: title,
    awardedAt: DateTime.utc(2026, 8, 1),
  );
}

void main() {
  test('featured pins refuse awards the learner does not own', () async {
    final repo = FakeShareCardRepository(
      awards: [_award('a1', 'quiz_rookie', 'Quiz Rookie')],
    );
    expect(
      () => repo.setFeatured(['missing']),
      throwsStateError,
    );
  });

  test('featured pins cap at three and preserve order', () async {
    final repo = FakeShareCardRepository(
      awards: [
        _award('a1', 'quiz_rookie', 'Quiz Rookie'),
        _award('a2', 'rising_star', 'Rising Star'),
        _award('a3', 'level_climber', 'Level Climber'),
        _award('a4', 'first_steps', 'First Steps'),
      ],
    );
    final pinned = await repo.setFeatured(['a4', 'a2', 'a1', 'a3']);
    expect(pinned, ['a4', 'a2', 'a1']);
  });

  test('achievement share uses a privacy-safe first name', () async {
    final repo = FakeShareCardRepository(
      displayName: 'Ali Alpha',
      awards: [_award('a1', 'quiz_rookie', 'Quiz Rookie')],
    );
    final card = await repo.forAchievement('a1');
    expect(card.firstName, 'Ali');
    expect(card.shareTextEn, isNot(contains('Alpha')));
  });

  test('quiz share builds from server score only', () async {
    final repo = FakeShareCardRepository(displayName: 'Sara Khan');
    final card = await repo.forQuizScore(scorePercent: 80, passed: true);
    expect(card.kind, ShareCardKind.quizScore);
    expect(card.shareTextEn, contains('Sara scored 80%'));
  });
}
