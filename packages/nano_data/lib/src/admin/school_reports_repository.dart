import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SCH-07 school-admin operational reports.
abstract class SchoolReportsRepository {
  Future<SchoolReportsSummary> load();
}

class FakeSchoolReportsRepository implements SchoolReportsRepository {
  FakeSchoolReportsRepository({SchoolReportsSummary? seed})
      : _summary = seed ??
            SchoolReportsSummary(
              schoolId: TenancyFixtures.alphaSchoolId,
              learnerCount: 30,
              teacherCount: 3,
              staffCount: 1,
              classCount: 4,
              subjectCount: 6,
              classSubjectCount: 8,
              uncoveredClassSubjectCount: 2,
              activeAssignmentCount: 5,
              teachersWithAssignmentCount: 2,
              studentsWithClassCount: 25,
              studentsWithoutClassCount: 5,
              openPeriodCount: 1,
              closedPeriodCount: 0,
              passingPercent: 40,
              attendanceMode: 'daily',
              reportCardFormat: 'both',
              teacherWorkload: const [
                TeacherWorkloadRow(displayName: 'Ms. Khan', activeCount: 3),
                TeacherWorkloadRow(displayName: 'Mr. Ali', activeCount: 2),
                TeacherWorkloadRow(displayName: 'Ms. Noor', activeCount: 0),
              ],
              generatedAt: DateTime.utc(2026, 8, 2),
            );

  SchoolReportsSummary _summary;
  var alwaysFail = false;

  @override
  Future<SchoolReportsSummary> load() async {
    if (alwaysFail) throw StateError('School reports unavailable');
    return _summary;
  }
}

class SupabaseSchoolReportsRepository implements SchoolReportsRepository {
  SupabaseSchoolReportsRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<SchoolReportsSummary> load() async {
    final raw = await _client.rpc('school_reports_summary');
    if (raw is! Map) throw StateError('School reports unavailable.');
    return SchoolReportsSummary.fromJson(Map<String, dynamic>.from(raw));
  }
}
