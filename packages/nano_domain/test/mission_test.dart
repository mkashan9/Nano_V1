import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses a my_missions row into a home plan item', () {
    final mission = MissionProgressView.fromRow({
      'mission_id': 'm1',
      'slug': 'daily_lesson',
      'cadence': 'daily',
      'title_en': 'Complete a lesson',
      'title_ur': 'ایک سبق مکمل کریں',
      'subtitle_en': 'Today',
      'subtitle_ur': 'آج',
      'xp_bonus': 15,
      'target_count': 1,
      'progress_count': 1,
      'period_key': '2026-08-02',
      'completed': true,
      'completed_at': '2026-08-02T10:00:00Z',
    });
    expect(mission.cadence, MissionCadence.daily);
    expect(mission.completed, isTrue);
    final plan = mission.toHomePlanItem(urdu: false);
    expect(plan.title, 'Complete a lesson');
    expect(plan.xpReward, 15);
    expect(plan.completed, isTrue);
    expect(plan.progress, 1);
  });
}
