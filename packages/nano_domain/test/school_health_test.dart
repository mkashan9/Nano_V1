import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('taxonomy lists documented events without unknown names', () {
    expect(AnalyticsEventTaxonomy.events, isNotEmpty);
    expect(
      AnalyticsEventTaxonomy.isKnown('learning.topic_completed'),
      isTrue,
    );
    expect(AnalyticsEventTaxonomy.isKnown('secret.track_child'), isFalse);
  });

  test('school health math maps rates and penalties to bands', () {
    final healthy = SchoolHealthMath.compute(
      attendanceCompletionRate: 0.95,
      assessmentPublicationRate: 0.9,
      learningParticipationRate: 0.88,
      uncoveredClassSubjectCount: 0,
      openIncidentCount: 0,
    );
    expect(healthy.band, SchoolHealthBand.healthy);
    expect(healthy.score, greaterThanOrEqualTo(75));

    final watch = SchoolHealthMath.compute(
      attendanceCompletionRate: 0.7,
      assessmentPublicationRate: 0.65,
      learningParticipationRate: 0.6,
      uncoveredClassSubjectCount: 1,
      openIncidentCount: 0,
    );
    expect(watch.band, SchoolHealthBand.watch);

    final critical = SchoolHealthMath.compute(
      attendanceCompletionRate: 0.2,
      assessmentPublicationRate: 0.2,
      learningParticipationRate: 0.2,
      uncoveredClassSubjectCount: 5,
      openIncidentCount: 3,
    );
    expect(critical.band, SchoolHealthBand.critical);
  });

  test('privacy review rejects forbidden keys on health payload', () {
    expect(
      () => SchoolHealthScore.fromJson({
        'attendance_completion_rate': 0.9,
        'email': 'a@b.c',
      }),
      throwsStateError,
    );
  });
}
