import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses safe analytics payload', () {
    final analytics = PlatformAnalytics.fromJson({
      'active_school_count': 2,
      'suspended_school_count': 0,
      'active_learner_count': 40,
      'independent_learner_count': 2,
      'published_subject_count': 2,
      'published_topic_count': 5,
      'live_game_count': 1,
      'published_notification_count': 3,
      'topic_completions_7d': 10,
      'xp_awards_7d': 20,
      'quiz_passes_7d': 5,
      'audit_events_7d': 12,
      'assets_awaiting_review': 1,
      'open_incident_count': 0,
      'action_breakdown_7d': [
        {'action': 'create', 'event_count': 4},
      ],
    });
    expect(analytics.activeSchoolCount, 2);
    expect(analytics.actionBreakdown7d.single.eventCount, 4);
  });

  test('rejects privacy-unsafe payload', () {
    expect(
      () => PlatformAnalytics.fromJson({
        'active_school_count': 1,
        'email': 'x@y.z',
      }),
      throwsStateError,
    );
  });
}
