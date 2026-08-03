import 'package:nano_domain/nano_domain.dart';

/// ANA-01 school health + event taxonomy (fake-first aggregates).
abstract class AnalyticsHealthRepository {
  Future<List<AnalyticsEventDefinition>> loadTaxonomy();

  Future<SchoolHealthSnapshot> loadSchoolHealth({required String schoolId});

  Future<List<SchoolHealthSnapshot>> loadPlatformSchoolHealth();
}

class FakeAnalyticsHealthRepository implements AnalyticsHealthRepository {
  FakeAnalyticsHealthRepository({
    List<SchoolHealthSnapshot>? schools,
    this.alwaysFail = false,
  }) : _schools = List.of(
          schools ??
              [
                SchoolHealthSnapshot(
                  schoolId: TenancyFixtures.alphaSchoolId,
                  schoolName: 'Alpha School',
                  health: SchoolHealthMath.compute(
                    attendanceCompletionRate: 0.92,
                    assessmentPublicationRate: 0.85,
                    learningParticipationRate: 0.78,
                    uncoveredClassSubjectCount: 0,
                    openIncidentCount: 0,
                  ),
                  generatedAt: DateTime.utc(2026, 8, 3, 8),
                ),
                SchoolHealthSnapshot(
                  schoolId: 'school-watch',
                  schoolName: 'Watch School',
                  health: SchoolHealthMath.compute(
                    attendanceCompletionRate: 0.61,
                    assessmentPublicationRate: 0.55,
                    learningParticipationRate: 0.48,
                    uncoveredClassSubjectCount: 2,
                    openIncidentCount: 1,
                  ),
                  generatedAt: DateTime.utc(2026, 8, 3, 8),
                ),
              ],
        );

  final List<SchoolHealthSnapshot> _schools;
  bool alwaysFail;

  @override
  Future<List<AnalyticsEventDefinition>> loadTaxonomy() async {
    if (alwaysFail) throw StateError('Taxonomy unavailable');
    return AnalyticsEventTaxonomy.events;
  }

  @override
  Future<SchoolHealthSnapshot> loadSchoolHealth({
    required String schoolId,
  }) async {
    if (alwaysFail) throw StateError('School health unavailable');
    for (final school in _schools) {
      if (school.schoolId == schoolId) return school;
    }
    // School-scoped callers still get a privacy-safe aggregate for their id.
    return SchoolHealthSnapshot(
      schoolId: schoolId,
      schoolName: 'Your school',
      health: SchoolHealthMath.compute(
        attendanceCompletionRate: 0.8,
        assessmentPublicationRate: 0.7,
        learningParticipationRate: 0.65,
        uncoveredClassSubjectCount: 1,
        openIncidentCount: 0,
      ),
      generatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<List<SchoolHealthSnapshot>> loadPlatformSchoolHealth() async {
    if (alwaysFail) throw StateError('Platform school health unavailable');
    return List.unmodifiable(_schools);
  }
}
