import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('snapshot parses policy and catalogs', () {
    final snapshot = GamificationAdminSnapshot.fromJson({
      'daily_cap': 250,
      'award_rules': [
        {'source_kind': 'video_completion', 'amount': 12, 'notes': 'n'},
      ],
      'level_rules': [
        {'level': 1, 'min_xp': 0},
        {'level': 2, 'min_xp': 200},
      ],
      'achievements': [
        {
          'id': 'a1',
          'slug': 'first_steps',
          'kind': 'sticker',
          'title_en': 'First Steps',
          'active': true,
        },
      ],
      'missions': [
        {
          'id': 'm1',
          'slug': 'daily_lesson',
          'cadence': 'daily',
          'title_en': 'Lesson',
          'target_count': 1,
          'xp_bonus': 15,
          'active': true,
        },
      ],
    });
    expect(snapshot.dailyCap, 250);
    expect(snapshot.xpPerLevel, 200);
    expect(snapshot.awardRules.single.isEditable, isTrue);
    expect(snapshot.achievements.single.active, isTrue);
  });
}
