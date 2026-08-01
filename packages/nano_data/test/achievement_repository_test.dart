import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('fake grant is idempotent by slug', () async {
    final repo = FakeAchievementRepository();
    final award = AchievementAward(
      awardId: '1',
      slug: 'first_steps',
      kind: AchievementKind.sticker,
      titleEn: 'First Steps',
      titleUr: 'پہلا قدم',
      awardedAt: DateTime.utc(2026, 8, 2),
    );
    repo.grant(award);
    repo.grant(award.copyWithId('2'));
    expect((await repo.mine()).length, 1);
  });

  test('profile reads awards from the repository when wired', () async {
    final achievements = FakeAchievementRepository(
      awards: [
        AchievementAward(
          awardId: 'a1',
          slug: 'first_steps',
          kind: AchievementKind.sticker,
          titleEn: 'First Steps',
          titleUr: 'پہلا قدم',
          awardedAt: DateTime.utc(2026, 8, 1),
        ),
        AchievementAward(
          awardId: 'a2',
          slug: 'quiz_rookie',
          kind: AchievementKind.achievement,
          titleEn: 'Quiz Rookie',
          titleUr: 'کوئز نوآموز',
          awardedAt: DateTime.utc(2026, 8, 2),
        ),
      ],
    );
    final profile = FakeStudentProfileRepository(achievements: achievements);
    final view = await profile.loadProfile(
      userId: 'u1',
      displayName: 'Ali',
      role: AppRole.juniorStudent,
    );
    expect(view.achievements.map((a) => a.slug), ['quiz_rookie', 'first_steps']);
    expect(view.achievements.first.isSticker, isFalse);
    expect(view.achievements.last.isSticker, isTrue);
  });

  test('profile keeps fixture achievements without a repository', () async {
    final profile = FakeStudentProfileRepository();
    final view = await profile.loadProfile(
      userId: 'u1',
      displayName: 'Ali',
      role: AppRole.juniorStudent,
    );
    expect(view.achievements, isNotEmpty);
    expect(view.achievements.first.title, 'First quiz cleared');
  });
}

extension on AchievementAward {
  AchievementAward copyWithId(String id) => AchievementAward(
        awardId: id,
        slug: slug,
        kind: kind,
        titleEn: titleEn,
        titleUr: titleUr,
        descriptionEn: descriptionEn,
        descriptionUr: descriptionUr,
        awardedAt: awardedAt,
      );
}
