import 'platform_dashboard.dart';

/// ANA-01 documented product/ops event taxonomy (privacy-safe names only).

class AnalyticsEventDefinition {
  const AnalyticsEventDefinition({
    required this.name,
    required this.question,
    required this.retentionDays,
  });

  final String name;
  final String question;
  final int retentionDays;

  factory AnalyticsEventDefinition.fromJson(Map<String, dynamic> json) {
    if (!PlatformDashboard.isPrivacySafePayload(json)) {
      throw StateError('Analytics event failed privacy review.');
    }
    return AnalyticsEventDefinition(
      name: json['name'] as String? ?? '',
      question: json['question'] as String? ?? '',
      retentionDays: (json['retention_days'] as num?)?.toInt() ?? 90,
    );
  }
}

/// Catalog of allowed analytics event names (no child PII payloads).
abstract final class AnalyticsEventTaxonomy {
  static const events = <AnalyticsEventDefinition>[
    AnalyticsEventDefinition(
      name: 'learning.topic_completed',
      question: 'How many topics did learners finish in the last 7 days?',
      retentionDays: 90,
    ),
    AnalyticsEventDefinition(
      name: 'quiz.attempt_passed',
      question: 'Are quiz passes trending up after content updates?',
      retentionDays: 90,
    ),
    AnalyticsEventDefinition(
      name: 'attendance.session_completed',
      question: 'What share of assigned classes finished attendance today?',
      retentionDays: 180,
    ),
    AnalyticsEventDefinition(
      name: 'assessment.published',
      question: 'Are teachers publishing assessments on schedule?',
      retentionDays: 180,
    ),
    AnalyticsEventDefinition(
      name: 'notification.delivered',
      question: 'Is push/inbox delivery healthy without duplicates?',
      retentionDays: 30,
    ),
    AnalyticsEventDefinition(
      name: 'safety.report_opened',
      question: 'How many new safety reports need triage?',
      retentionDays: 365,
    ),
    AnalyticsEventDefinition(
      name: 'game.session_verified',
      question: 'Are trusted game results flowing into XP?',
      retentionDays: 90,
    ),
  ];

  static bool isKnown(String name) =>
      events.any((event) => event.name == name);

  static AnalyticsEventDefinition? byName(String name) {
    for (final event in events) {
      if (event.name == name) return event;
    }
    return null;
  }
}

enum SchoolHealthBand { healthy, watch, critical }

class SchoolHealthScore {
  const SchoolHealthScore({
    required this.score,
    required this.band,
    required this.attendanceCompletionRate,
    required this.assessmentPublicationRate,
    required this.learningParticipationRate,
    required this.uncoveredClassSubjectCount,
    required this.openIncidentCount,
  });

  /// 0–100 composite.
  final int score;
  final SchoolHealthBand band;
  final double attendanceCompletionRate;
  final double assessmentPublicationRate;
  final double learningParticipationRate;
  final int uncoveredClassSubjectCount;
  final int openIncidentCount;

  factory SchoolHealthScore.fromJson(Map<String, dynamic> json) {
    if (!PlatformDashboard.isPrivacySafePayload(json)) {
      throw StateError('School health failed privacy review.');
    }
    final computed = SchoolHealthMath.compute(
      attendanceCompletionRate:
          (json['attendance_completion_rate'] as num?)?.toDouble() ?? 0,
      assessmentPublicationRate:
          (json['assessment_publication_rate'] as num?)?.toDouble() ?? 0,
      learningParticipationRate:
          (json['learning_participation_rate'] as num?)?.toDouble() ?? 0,
      uncoveredClassSubjectCount:
          (json['uncovered_class_subject_count'] as num?)?.toInt() ?? 0,
      openIncidentCount: (json['open_incident_count'] as num?)?.toInt() ?? 0,
    );
    return computed;
  }
}

class SchoolHealthSnapshot {
  const SchoolHealthSnapshot({
    required this.schoolId,
    required this.schoolName,
    required this.health,
    this.generatedAt,
  });

  final String schoolId;
  final String schoolName;
  final SchoolHealthScore health;
  final DateTime? generatedAt;

  factory SchoolHealthSnapshot.fromJson(Map<String, dynamic> json) {
    if (!PlatformDashboard.isPrivacySafePayload(json)) {
      throw StateError('School health snapshot failed privacy review.');
    }
    // school_name is an org label, not learner PII.
    return SchoolHealthSnapshot(
      schoolId: json['school_id'] as String? ?? '',
      schoolName: json['school_name'] as String? ?? '',
      health: SchoolHealthScore.fromJson(json),
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

/// Documented composite used by dashboards (traceable inputs → score).
abstract final class SchoolHealthMath {
  static SchoolHealthBand bandFor(int score) {
    if (score >= 75) return SchoolHealthBand.healthy;
    if (score >= 50) return SchoolHealthBand.watch;
    return SchoolHealthBand.critical;
  }

  static SchoolHealthScore compute({
    required double attendanceCompletionRate,
    required double assessmentPublicationRate,
    required double learningParticipationRate,
    required int uncoveredClassSubjectCount,
    required int openIncidentCount,
  }) {
    final attendance = attendanceCompletionRate.clamp(0, 1);
    final assessment = assessmentPublicationRate.clamp(0, 1);
    final learning = learningParticipationRate.clamp(0, 1);
    var score = ((attendance * 40) + (assessment * 30) + (learning * 30)).round();
    score -= (uncoveredClassSubjectCount * 5).clamp(0, 25);
    score -= (openIncidentCount * 8).clamp(0, 24);
    score = score.clamp(0, 100);
    return SchoolHealthScore(
      score: score,
      band: bandFor(score),
      attendanceCompletionRate: attendance.toDouble(),
      assessmentPublicationRate: assessment.toDouble(),
      learningParticipationRate: learning.toDouble(),
      uncoveredClassSubjectCount: uncoveredClassSubjectCount,
      openIncidentCount: openIncidentCount,
    );
  }
}
