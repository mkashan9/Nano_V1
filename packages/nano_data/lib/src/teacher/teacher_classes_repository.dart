import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// TCH-02 My Classes list and assignment-scoped roster.
abstract class TeacherClassesRepository {
  Future<TeacherMyClasses> listMine();
  Future<TeacherClassRoster> loadRoster(String assignmentId);
}

class FakeTeacherClassesRepository implements TeacherClassesRepository {
  FakeTeacherClassesRepository({
    TeacherMyClasses? seed,
    Map<String, TeacherClassRoster>? rosters,
  })  : _mine = seed ??
            TeacherMyClasses(
              schoolId: TenancyFixtures.alphaSchoolId,
              teacherId: TenancyFixtures.teacherId,
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
            ),
        _rosters = rosters ??
            {
              'asg-1': TeacherClassRoster(
                assignmentId: 'asg-1',
                schoolId: TenancyFixtures.alphaSchoolId,
                classId: 'class-5a',
                classLabel: '5-A',
                sectionName: '',
                subjectCode: 'MATH',
                subjectName: 'Mathematics',
                studentCount: 2,
                students: const [
                  TeacherRosterStudent(
                    id: TenancyFixtures.aliAlphaId,
                    displayName: 'Ali Khan',
                    enrollmentStatus: 'active',
                  ),
                  TeacherRosterStudent(
                    id: 'student-2',
                    displayName: 'Sara Ahmed',
                    enrollmentStatus: 'active',
                  ),
                ],
                generatedAt: DateTime.utc(2026, 8, 2),
              ),
              'asg-2': TeacherClassRoster(
                assignmentId: 'asg-2',
                schoolId: TenancyFixtures.alphaSchoolId,
                classId: 'class-5b',
                sectionId: 'sec-1',
                classLabel: '5-B',
                sectionName: 'Morning',
                subjectCode: 'ENG',
                subjectName: 'English',
                studentCount: 1,
                students: const [
                  TeacherRosterStudent(
                    id: 'student-3',
                    displayName: 'Omar Raza',
                    enrollmentStatus: 'active',
                  ),
                ],
                generatedAt: DateTime.utc(2026, 8, 2),
              ),
            };

  TeacherMyClasses _mine;
  final Map<String, TeacherClassRoster> _rosters;
  var alwaysFail = false;

  @override
  Future<TeacherMyClasses> listMine() async {
    if (alwaysFail) throw StateError('Teacher classes unavailable');
    return _mine;
  }

  @override
  Future<TeacherClassRoster> loadRoster(String assignmentId) async {
    if (alwaysFail) throw StateError('Teacher roster unavailable');
    final roster = _rosters[assignmentId];
    if (roster == null) {
      throw StateError('Assignment is not in your active scope.');
    }
    return roster;
  }
}

class SupabaseTeacherClassesRepository implements TeacherClassesRepository {
  SupabaseTeacherClassesRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TeacherMyClasses> listMine() async {
    final raw = await _client.rpc('teacher_my_classes');
    if (raw is! Map) throw StateError('Teacher classes unavailable.');
    return TeacherMyClasses.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherClassRoster> loadRoster(String assignmentId) async {
    final raw = await _client.rpc(
      'teacher_class_roster',
      params: {'p_assignment_id': assignmentId},
    );
    if (raw is! Map) throw StateError('Teacher roster unavailable.');
    return TeacherClassRoster.fromJson(Map<String, dynamic>.from(raw));
  }
}
