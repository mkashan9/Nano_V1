import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SCH-05 school-admin teacher assignment matrix.
abstract class TeacherAssignmentRepository {
  Future<TeacherAssignmentMatrix> load();

  Future<TeacherAssignmentMatrix> assign({
    required String teacherUserId,
    required String classId,
    required String schoolSubjectId,
    String? sectionId,
    String? startsOn,
  });

  Future<TeacherAssignmentMatrix> end({
    required String assignmentId,
    required String reason,
  });

  Future<TeacherAssignmentMatrix> replace({
    required String assignmentId,
    required String newTeacherUserId,
    required String reason,
  });
}

class FakeTeacherAssignmentRepository implements TeacherAssignmentRepository {
  FakeTeacherAssignmentRepository({TeacherAssignmentMatrix? seed})
      : _matrix = seed ??
            TeacherAssignmentMatrix(
              schoolId: TenancyFixtures.alphaSchoolId,
              assignments: const [
                TeacherAssignmentRow(
                  id: 'asg-1',
                  teacherUserId: TenancyFixtures.teacherId,
                  teacherName: 'Ms. Khan',
                  classId: 'class-5a',
                  sectionId: null,
                  schoolSubjectId: 'subj-math',
                  classLabel: '5-A',
                  sectionName: '',
                  subjectCode: 'MATH',
                  subjectName: 'Mathematics',
                  status: 'active',
                  startsOn: '2026-08-01',
                  endsOn: null,
                ),
              ],
              teachers: const [
                AssignmentTeacherOption(
                  id: TenancyFixtures.teacherId,
                  displayName: 'Ms. Khan',
                ),
                AssignmentTeacherOption(
                  id: 'teacher-2',
                  displayName: 'Mr. Ali',
                ),
              ],
              classes: const [
                AssignmentClassOption(id: 'class-5a', name: '5-A'),
                AssignmentClassOption(id: 'class-5b', name: '5-B'),
              ],
              sections: const [
                AssignmentSectionOption(
                  id: 'sec-1',
                  classId: 'class-5a',
                  name: 'Morning',
                ),
              ],
              subjects: const [
                AssignmentSubjectOption(
                  id: 'subj-math',
                  name: 'Mathematics',
                  code: 'MATH',
                ),
                AssignmentSubjectOption(
                  id: 'subj-eng',
                  name: 'English',
                  code: 'ENG',
                ),
              ],
              uncovered: const [
                UncoveredClassSubject(
                  classId: 'class-5a',
                  className: '5-A',
                  sectionId: null,
                  sectionName: null,
                  schoolSubjectId: 'subj-eng',
                  subjectCode: 'ENG',
                  subjectName: 'English',
                ),
              ],
              conflicts: const [],
              workload: const [
                TeacherWorkload(
                  teacherUserId: TenancyFixtures.teacherId,
                  displayName: 'Ms. Khan',
                  activeCount: 1,
                ),
                TeacherWorkload(
                  teacherUserId: 'teacher-2',
                  displayName: 'Mr. Ali',
                  activeCount: 0,
                ),
              ],
            );

  TeacherAssignmentMatrix _matrix;
  var alwaysFail = false;
  var assignCount = 0;
  final endReasons = <String>[];

  TeacherAssignmentMatrix _recompute(TeacherAssignmentMatrix base) {
    final active = [
      for (final row in base.assignments)
        if (row.isActive) row,
    ];
    final uncovered = <UncoveredClassSubject>[
      for (final subject in base.subjects)
        for (final klass in base.classes)
          if (!active.any(
            (a) =>
                a.classId == klass.id &&
                a.schoolSubjectId == subject.id &&
                a.sectionId == null,
          ))
            UncoveredClassSubject(
              classId: klass.id,
              className: klass.name,
              sectionId: null,
              sectionName: null,
              schoolSubjectId: subject.id,
              subjectCode: subject.code,
              subjectName: subject.name,
            ),
    ];
    final conflictMap = <String, List<TeacherAssignmentRow>>{};
    for (final row in active) {
      if (row.classId == null || row.schoolSubjectId == null) continue;
      final key = '${row.classId}|${row.sectionId}|${row.schoolSubjectId}';
      conflictMap.putIfAbsent(key, () => []).add(row);
    }
    final conflicts = [
      for (final entry in conflictMap.entries)
        if (entry.value.length > 1)
          AssignmentConflict(
            classId: entry.value.first.classId,
            sectionId: entry.value.first.sectionId,
            schoolSubjectId: entry.value.first.schoolSubjectId,
            classLabel: entry.value.first.classLabel,
            subjectCode: entry.value.first.subjectCode,
            teacherCount: entry.value.length,
            teacherNames: entry.value.map((e) => e.teacherName).join(', '),
          ),
    ];
    final workload = [
      for (final teacher in base.teachers)
        TeacherWorkload(
          teacherUserId: teacher.id,
          displayName: teacher.displayName,
          activeCount: active.where((a) => a.teacherUserId == teacher.id).length,
        ),
    ];
    return TeacherAssignmentMatrix(
      schoolId: base.schoolId,
      assignments: base.assignments,
      teachers: base.teachers,
      classes: base.classes,
      sections: base.sections,
      subjects: base.subjects,
      uncovered: uncovered,
      conflicts: conflicts,
      workload: workload,
    );
  }

  @override
  Future<TeacherAssignmentMatrix> load() async {
    if (alwaysFail) throw StateError('Assignments unavailable');
    return _recompute(_matrix);
  }

  @override
  Future<TeacherAssignmentMatrix> assign({
    required String teacherUserId,
    required String classId,
    required String schoolSubjectId,
    String? sectionId,
    String? startsOn,
  }) async {
    if (alwaysFail) throw StateError('Assign failed');
    AssignmentTeacherOption? teacher;
    for (final t in _matrix.teachers) {
      if (t.id == teacherUserId) teacher = t;
    }
    if (teacher == null) throw StateError('Teacher not found in this school.');
    AssignmentClassOption? klass;
    for (final c in _matrix.classes) {
      if (c.id == classId) klass = c;
    }
    if (klass == null) throw StateError('Active class required.');
    AssignmentSubjectOption? subject;
    for (final s in _matrix.subjects) {
      if (s.id == schoolSubjectId) subject = s;
    }
    if (subject == null) throw StateError('Active subject required.');
    if (_matrix.assignments.any(
      (a) =>
          a.isActive &&
          a.teacherUserId == teacherUserId &&
          a.classId == classId &&
          a.schoolSubjectId == schoolSubjectId &&
          a.sectionId == sectionId,
    )) {
      throw StateError('Teacher already assigned to this class/subject scope.');
    }
    assignCount++;
    var sectionName = '';
    if (sectionId != null) {
      for (final s in _matrix.sections) {
        if (s.id == sectionId) sectionName = s.name;
      }
    }
    final row = TeacherAssignmentRow(
      id: 'asg-${_matrix.assignments.length + 1}',
      teacherUserId: teacherUserId,
      teacherName: teacher.displayName,
      classId: classId,
      sectionId: sectionId,
      schoolSubjectId: schoolSubjectId,
      classLabel: klass.name,
      sectionName: sectionName,
      subjectCode: subject.code,
      subjectName: subject.name,
      status: 'active',
      startsOn: startsOn ?? '2026-08-02',
      endsOn: null,
    );
    _matrix = TeacherAssignmentMatrix(
      schoolId: _matrix.schoolId,
      assignments: [..._matrix.assignments, row],
      teachers: _matrix.teachers,
      classes: _matrix.classes,
      sections: _matrix.sections,
      subjects: _matrix.subjects,
      uncovered: _matrix.uncovered,
      conflicts: _matrix.conflicts,
      workload: _matrix.workload,
    );
    return _recompute(_matrix);
  }

  @override
  Future<TeacherAssignmentMatrix> end({
    required String assignmentId,
    required String reason,
  }) async {
    if (alwaysFail) throw StateError('End assignment failed');
    if (reason.trim().isEmpty) throw StateError('A reason is required.');
    final index = _matrix.assignments.indexWhere((a) => a.id == assignmentId);
    if (index < 0) throw StateError('Assignment not found in this school.');
    final current = _matrix.assignments[index];
    if (!current.isActive) throw StateError('Assignment is already ended.');
    endReasons.add(reason.trim());
    final updated = List<TeacherAssignmentRow>.of(_matrix.assignments);
    updated[index] = TeacherAssignmentRow(
      id: current.id,
      teacherUserId: current.teacherUserId,
      teacherName: current.teacherName,
      classId: current.classId,
      sectionId: current.sectionId,
      schoolSubjectId: current.schoolSubjectId,
      classLabel: current.classLabel,
      sectionName: current.sectionName,
      subjectCode: current.subjectCode,
      subjectName: current.subjectName,
      status: 'left',
      startsOn: current.startsOn,
      endsOn: '2026-08-02',
    );
    _matrix = TeacherAssignmentMatrix(
      schoolId: _matrix.schoolId,
      assignments: updated,
      teachers: _matrix.teachers,
      classes: _matrix.classes,
      sections: _matrix.sections,
      subjects: _matrix.subjects,
      uncovered: _matrix.uncovered,
      conflicts: _matrix.conflicts,
      workload: _matrix.workload,
    );
    return _recompute(_matrix);
  }

  @override
  Future<TeacherAssignmentMatrix> replace({
    required String assignmentId,
    required String newTeacherUserId,
    required String reason,
  }) async {
    final current = _matrix.assignments.firstWhere(
      (a) => a.id == assignmentId,
      orElse: () => throw StateError('Assignment not found in this school.'),
    );
    await end(assignmentId: assignmentId, reason: reason);
    return assign(
      teacherUserId: newTeacherUserId,
      classId: current.classId!,
      schoolSubjectId: current.schoolSubjectId!,
      sectionId: current.sectionId,
    );
  }
}

class SupabaseTeacherAssignmentRepository
    implements TeacherAssignmentRepository {
  SupabaseTeacherAssignmentRepository(this._client);

  final SupabaseClient _client;

  TeacherAssignmentMatrix _parse(dynamic raw) {
    if (raw is! Map) throw StateError('Assignment matrix unavailable.');
    return TeacherAssignmentMatrix.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherAssignmentMatrix> load() async {
    final raw = await _client.rpc('list_teacher_assignment_matrix');
    return _parse(raw);
  }

  @override
  Future<TeacherAssignmentMatrix> assign({
    required String teacherUserId,
    required String classId,
    required String schoolSubjectId,
    String? sectionId,
    String? startsOn,
  }) async {
    final raw = await _client.rpc(
      'assign_teacher',
      params: {
        'p_teacher_user_id': teacherUserId,
        'p_class_id': classId,
        'p_school_subject_id': schoolSubjectId,
        'p_section_id': sectionId,
        'p_starts_on': startsOn,
      },
    );
    return _parse(raw);
  }

  @override
  Future<TeacherAssignmentMatrix> end({
    required String assignmentId,
    required String reason,
  }) async {
    final raw = await _client.rpc(
      'end_teacher_assignment',
      params: {
        'p_assignment_id': assignmentId,
        'p_reason': reason,
      },
    );
    return _parse(raw);
  }

  @override
  Future<TeacherAssignmentMatrix> replace({
    required String assignmentId,
    required String newTeacherUserId,
    required String reason,
  }) async {
    final raw = await _client.rpc(
      'replace_teacher_assignment',
      params: {
        'p_assignment_id': assignmentId,
        'p_new_teacher_user_id': newTeacherUserId,
        'p_reason': reason,
      },
    );
    return _parse(raw);
  }
}
