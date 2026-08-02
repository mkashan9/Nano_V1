import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// TCH-01 teacher dashboard (caller-scoped assignments).
abstract class TeacherDashboardRepository {
  Future<TeacherDashboard> load();
}

class FakeTeacherDashboardRepository implements TeacherDashboardRepository {
  FakeTeacherDashboardRepository({TeacherDashboard? seed})
      : _dashboard = seed ??
            TeacherDashboard(
              schoolId: TenancyFixtures.alphaSchoolId,
              schoolCode: 'ALPHA01',
              schoolName: 'Alpha Academy',
              teacherId: TenancyFixtures.teacherId,
              teacherName: 'Ms. Khan',
              activeAssignmentCount: 2,
              pendingAttendanceCount: 0,
              draftAssessmentCount: 0,
              unpublishedMarksCount: 0,
              recentClassroomCount: 0,
              assignments: const [
                TeacherAssignmentScope(
                  id: 'asg-1',
                  classId: 'class-5a',
                  classLabel: '5-A',
                  sectionName: '',
                  subjectCode: 'MATH',
                  subjectName: 'Mathematics',
                  status: 'active',
                  schoolSubjectId: 'subj-math',
                  startsOn: '2026-08-01',
                ),
                TeacherAssignmentScope(
                  id: 'asg-2',
                  classId: 'class-5b',
                  classLabel: '5-B',
                  sectionName: 'Morning',
                  subjectCode: 'ENG',
                  subjectName: 'English',
                  status: 'active',
                  schoolSubjectId: 'subj-eng',
                  sectionId: 'sec-1',
                  startsOn: '2026-08-01',
                ),
              ],
              generatedAt: DateTime.utc(2026, 8, 2),
            );

  TeacherDashboard _dashboard;
  var alwaysFail = false;

  @override
  Future<TeacherDashboard> load() async {
    if (alwaysFail) throw StateError('Teacher dashboard unavailable');
    return _dashboard;
  }
}

class SupabaseTeacherDashboardRepository implements TeacherDashboardRepository {
  SupabaseTeacherDashboardRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TeacherDashboard> load() async {
    final raw = await _client.rpc('teacher_dashboard');
    if (raw is! Map) throw StateError('Teacher dashboard unavailable.');
    return TeacherDashboard.fromJson(Map<String, dynamic>.from(raw));
  }
}
