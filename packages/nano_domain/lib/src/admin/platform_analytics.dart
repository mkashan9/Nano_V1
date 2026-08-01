import 'platform_dashboard.dart';

/// ADM-08 platform analytics — safe aggregates only (no PII keys).
class PlatformAnalytics {
  const PlatformAnalytics({
    required this.activeSchoolCount,
    required this.suspendedSchoolCount,
    required this.activeLearnerCount,
    required this.independentLearnerCount,
    required this.publishedSubjectCount,
    required this.publishedTopicCount,
    required this.liveGameCount,
    required this.publishedNotificationCount,
    required this.topicCompletions7d,
    required this.xpAwards7d,
    required this.quizPasses7d,
    required this.auditEvents7d,
    required this.assetsAwaitingReview,
    required this.openIncidentCount,
    this.actionBreakdown7d = const [],
    this.generatedAt,
  });

  final int activeSchoolCount;
  final int suspendedSchoolCount;
  final int activeLearnerCount;
  final int independentLearnerCount;
  final int publishedSubjectCount;
  final int publishedTopicCount;
  final int liveGameCount;
  final int publishedNotificationCount;
  final int topicCompletions7d;
  final int xpAwards7d;
  final int quizPasses7d;
  final int auditEvents7d;
  final int assetsAwaitingReview;
  final int openIncidentCount;
  final List<AnalyticsActionCount> actionBreakdown7d;
  final DateTime? generatedAt;

  factory PlatformAnalytics.fromJson(Map<String, dynamic> json) {
    if (!PlatformDashboard.isPrivacySafePayload(json)) {
      throw StateError('Platform analytics failed privacy review.');
    }
    final breakdownRaw = json['action_breakdown_7d'];
    return PlatformAnalytics(
      activeSchoolCount: (json['active_school_count'] as num?)?.toInt() ?? 0,
      suspendedSchoolCount:
          (json['suspended_school_count'] as num?)?.toInt() ?? 0,
      activeLearnerCount: (json['active_learner_count'] as num?)?.toInt() ?? 0,
      independentLearnerCount:
          (json['independent_learner_count'] as num?)?.toInt() ?? 0,
      publishedSubjectCount:
          (json['published_subject_count'] as num?)?.toInt() ?? 0,
      publishedTopicCount:
          (json['published_topic_count'] as num?)?.toInt() ?? 0,
      liveGameCount: (json['live_game_count'] as num?)?.toInt() ?? 0,
      publishedNotificationCount:
          (json['published_notification_count'] as num?)?.toInt() ?? 0,
      topicCompletions7d: (json['topic_completions_7d'] as num?)?.toInt() ?? 0,
      xpAwards7d: (json['xp_awards_7d'] as num?)?.toInt() ?? 0,
      quizPasses7d: (json['quiz_passes_7d'] as num?)?.toInt() ?? 0,
      auditEvents7d: (json['audit_events_7d'] as num?)?.toInt() ?? 0,
      assetsAwaitingReview:
          (json['assets_awaiting_review'] as num?)?.toInt() ?? 0,
      openIncidentCount: (json['open_incident_count'] as num?)?.toInt() ?? 0,
      actionBreakdown7d: [
        if (breakdownRaw is List)
          for (final row in breakdownRaw.whereType<Map>())
            AnalyticsActionCount.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class AnalyticsActionCount {
  const AnalyticsActionCount({
    required this.action,
    required this.eventCount,
  });

  final String action;
  final int eventCount;

  factory AnalyticsActionCount.fromJson(Map<String, dynamic> json) {
    if (!PlatformDashboard.isPrivacySafePayload(json)) {
      throw StateError('Action breakdown failed privacy review.');
    }
    return AnalyticsActionCount(
      action: json['action'] as String? ?? 'other',
      eventCount: (json['event_count'] as num?)?.toInt() ?? 0,
    );
  }
}
