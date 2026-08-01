import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SCH-04 school-admin student management and CSV import.
abstract class SchoolStudentRepository {
  Future<List<SchoolStudent>> list({String query = ''});

  Future<StudentCreateResult> create({
    required String displayName,
    required String email,
    String? tempPassword,
    String? classId,
  });

  Future<List<SchoolStudent>> setStatus({
    required String userId,
    required String status,
    required String reason,
  });

  Future<List<SchoolStudent>> enroll({
    required String userId,
    required String classId,
  });

  Future<StudentImportPreview> previewImport(List<Map<String, String>> rows);

  Future<StudentImportCommitResult> commitImport(
    List<Map<String, String>> rows,
  );
}

class FakeSchoolStudentRepository implements SchoolStudentRepository {
  FakeSchoolStudentRepository({List<SchoolStudent>? seed})
      : _students = List.of(
          seed ??
              [
                const SchoolStudent(
                  id: TenancyFixtures.aliAlphaId,
                  displayName: 'Ali',
                  email: 'ali@alpha.nano.dev',
                  profileStatus: 'active',
                  membershipStatus: 'active',
                  classId: 'class-5a',
                  className: '5-A',
                ),
              ],
        );

  final List<SchoolStudent> _students;
  var alwaysFail = false;
  var createCount = 0;
  final statusReasons = <String>[];

  @override
  Future<List<SchoolStudent>> list({String query = ''}) async {
    if (alwaysFail) throw StateError('Students unavailable');
    final q = query.trim().toLowerCase();
    return [
      for (final s in _students)
        if (q.isEmpty ||
            s.displayName.toLowerCase().contains(q) ||
            s.email.toLowerCase().contains(q) ||
            (s.className ?? '').toLowerCase().contains(q))
          s,
    ];
  }

  @override
  Future<StudentCreateResult> create({
    required String displayName,
    required String email,
    String? tempPassword,
    String? classId,
  }) async {
    if (alwaysFail) throw StateError('Create student failed');
    final name = displayName.trim();
    final mail = email.trim().toLowerCase();
    if (name.isEmpty) throw StateError('Display name is required.');
    if (!mail.contains('@')) throw StateError('A valid email is required.');
    if (_students.any((s) => s.email == mail)) {
      throw StateError('Email already registered.');
    }
    createCount++;
    final student = SchoolStudent(
      id: 'student-${_students.length + 1}',
      displayName: name,
      email: mail,
      profileStatus: 'active',
      membershipStatus: 'active',
      classId: classId,
      className: classId == null ? null : 'Class',
    );
    _students.add(student);
    return StudentCreateResult(
      student: student,
      tempPassword: tempPassword?.trim().isNotEmpty == true
          ? tempPassword!.trim()
          : 'NanoLearnTemp1!',
      students: List.of(_students),
    );
  }

  @override
  Future<List<SchoolStudent>> setStatus({
    required String userId,
    required String status,
    required String reason,
  }) async {
    if (alwaysFail) throw StateError('Status update failed');
    if (reason.trim().isEmpty) throw StateError('A reason is required.');
    if (status != 'active' && status != 'suspended') {
      throw StateError('Only active or suspended is allowed.');
    }
    final index = _students.indexWhere((s) => s.id == userId);
    if (index < 0) throw StateError('Student not found in this school.');
    statusReasons.add(reason.trim());
    final current = _students[index];
    _students[index] = SchoolStudent(
      id: current.id,
      displayName: current.displayName,
      email: current.email,
      profileStatus: status,
      membershipStatus: status,
      classId: status == 'suspended' ? null : current.classId,
      className: status == 'suspended' ? null : current.className,
      sectionId: status == 'suspended' ? null : current.sectionId,
      sectionName: status == 'suspended' ? null : current.sectionName,
    );
    return List.of(_students);
  }

  @override
  Future<List<SchoolStudent>> enroll({
    required String userId,
    required String classId,
  }) async {
    if (alwaysFail) throw StateError('Enrollment failed');
    final index = _students.indexWhere((s) => s.id == userId);
    if (index < 0) throw StateError('Student not found in this school.');
    final current = _students[index];
    _students[index] = SchoolStudent(
      id: current.id,
      displayName: current.displayName,
      email: current.email,
      profileStatus: current.profileStatus,
      membershipStatus: current.membershipStatus,
      classId: classId,
      className: 'Class',
    );
    return List.of(_students);
  }

  @override
  Future<StudentImportPreview> previewImport(
    List<Map<String, String>> rows,
  ) async {
    if (alwaysFail) throw StateError('Import preview failed');
    final ok = <StudentImportRow>[];
    final fail = <StudentImportFailure>[];
    final seen = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final name = (rows[i]['display_name'] ?? '').trim();
      final email = (rows[i]['email'] ?? '').trim().toLowerCase();
      final className = (rows[i]['class_name'] ?? '').trim();
      final rowNum = i + 1;
      if (name.isEmpty || email.isEmpty) {
        fail.add(StudentImportFailure(
          row: rowNum,
          email: email,
          error: 'display_name and email are required',
        ));
        continue;
      }
      if (!email.contains('@')) {
        fail.add(StudentImportFailure(
          row: rowNum,
          email: email,
          error: 'invalid email',
        ));
        continue;
      }
      if (seen.contains(email)) {
        fail.add(StudentImportFailure(
          row: rowNum,
          email: email,
          error: 'duplicate in file',
        ));
        continue;
      }
      if (_students.any((s) => s.email == email)) {
        fail.add(StudentImportFailure(
          row: rowNum,
          email: email,
          error: 'email already registered',
        ));
        continue;
      }
      seen.add(email);
      ok.add(StudentImportRow(
        row: rowNum,
        displayName: name,
        email: email,
        className: className.isEmpty ? null : className,
        classId: className.isEmpty ? null : 'class-fake',
      ));
    }
    return StudentImportPreview(
      okCount: ok.length,
      failCount: fail.length,
      okRows: ok,
      failedRows: fail,
    );
  }

  @override
  Future<StudentImportCommitResult> commitImport(
    List<Map<String, String>> rows,
  ) async {
    final preview = await previewImport(rows);
    if (!preview.canCommit) {
      return StudentImportCommitResult(
        committed: false,
        message: 'Fix failed rows before commit. Nothing was written.',
        preview: preview,
        created: const [],
        students: List.of(_students),
      );
    }
    final created = <Map<String, dynamic>>[];
    for (final row in preview.okRows) {
      final result = await create(
        displayName: row.displayName,
        email: row.email,
        classId: row.classId,
      );
      created.add({
        'email': row.email,
        'display_name': row.displayName,
        'id': result.student.id,
        'temp_password': result.tempPassword,
        'class_name': row.className,
      });
    }
    return StudentImportCommitResult(
      committed: true,
      message: 'Import committed.',
      preview: preview,
      created: created,
      students: List.of(_students),
    );
  }
}

class SupabaseSchoolStudentRepository implements SchoolStudentRepository {
  SupabaseSchoolStudentRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SchoolStudent>> list({String query = ''}) async {
    final raw = await _client.rpc(
      'list_school_students',
      params: {'p_query': query},
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        SchoolStudent.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<StudentCreateResult> create({
    required String displayName,
    required String email,
    String? tempPassword,
    String? classId,
  }) async {
    final raw = await _client.rpc(
      'create_school_student',
      params: {
        'p_display_name': displayName,
        'p_email': email,
        'p_temp_password': tempPassword,
        'p_class_id': classId,
      },
    );
    if (raw is! Map) throw StateError('Create student failed.');
    return StudentCreateResult.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<SchoolStudent>> setStatus({
    required String userId,
    required String status,
    required String reason,
  }) async {
    final raw = await _client.rpc(
      'set_school_student_status',
      params: {
        'p_user_id': userId,
        'p_status': status,
        'p_reason': reason,
      },
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        SchoolStudent.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<List<SchoolStudent>> enroll({
    required String userId,
    required String classId,
  }) async {
    final raw = await _client.rpc(
      'enroll_school_student',
      params: {'p_user_id': userId, 'p_class_id': classId},
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        SchoolStudent.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<StudentImportPreview> previewImport(
    List<Map<String, String>> rows,
  ) async {
    final raw = await _client.rpc(
      'preview_student_import',
      params: {'p_rows': rows},
    );
    if (raw is! Map) throw StateError('Import preview failed.');
    return StudentImportPreview.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<StudentImportCommitResult> commitImport(
    List<Map<String, String>> rows,
  ) async {
    final raw = await _client.rpc(
      'commit_student_import',
      params: {'p_rows': rows},
    );
    if (raw is! Map) throw StateError('Import commit failed.');
    return StudentImportCommitResult.fromJson(Map<String, dynamic>.from(raw));
  }
}
