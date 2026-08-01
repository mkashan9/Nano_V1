import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  group('AchievementAward', () {
    test('parses a my_achievements row', () {
      final award = AchievementAward.fromRow({
        'award_id': 'a1',
        'slug': 'first_steps',
        'kind': 'sticker',
        'title_en': 'First Steps',
        'title_ur': 'پہلا قدم',
        'description_en': 'Finish your first topic video.',
        'description_ur': '',
        'awarded_at': '2026-08-02T00:00:00Z',
      });
      expect(award.isSticker, isTrue);
      expect(award.titleFor(urdu: false), 'First Steps');
      expect(award.titleFor(urdu: true), 'پہلا قدم');
    });
  });

  group('ProfileAchievement', () {
    test('maps from an award with locale', () {
      final award = AchievementAward(
        awardId: 'a1',
        slug: 'quiz_rookie',
        kind: AchievementKind.achievement,
        titleEn: 'Quiz Rookie',
        titleUr: 'کوئز نوآموز',
        awardedAt: DateTime.utc(2026, 8, 2),
      );
      final en = ProfileAchievement.fromAward(award, urdu: false);
      final ur = ProfileAchievement.fromAward(award, urdu: true);
      expect(en.title, 'Quiz Rookie');
      expect(ur.title, 'کوئز نوآموز');
      expect(en.isSticker, isFalse);
      expect(en.slug, 'quiz_rookie');
    });
  });
}
