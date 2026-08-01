import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// SCH-03 school-admin teacher management and CSV import.
abstract class SchoolTeacherRepository {
  Future<List<SchoolTeacher>> list({String query = ''});

  Future<TeacherCreateResult> create({
    required String displayName,
    required String email,
    String? tempPassword,
  });

  Future<List<SchoolTeacher>> setStatus({
    required String userId,
    required String status,
    required String reason,
  });

  Future<TeacherImportPreview> previewImport(List<Map<String, String>> rows);

  Future<TeacherImportCommitResult> commitImport(
    List<Map<String, String>> rows,
  );
}

class FakeSchoolTeacherRepository implements SchoolTeacherRepository {
  FakeSchoolTeacherRepository({List<SchoolTeacher>? seed})
      : _teachers = List.of(
          seed ??
              [
                const SchoolTeacher(
                  id: TenancyFixtures.teacherId,
                  displayName: 'Ms. Khan',
                  email: 'teacher@alpha.nano.dev',
                  profileStatus: 'active',
                  membershipStatus: 'active',
                ),
              ],
        );

  final List<SchoolTeacher> _teachers;
  var alwaysFail = false;
  var createCount = 0;
  final statusReasons = <String>[];

  @override
  Future<List<SchoolTeacher>> list({String query = ''}) async {
    if (alwaysFail) throw StateError('Teachers unavailable');
    final q = query.trim().toLowerCase();
    return [
      for (final t in _teachers)
        if (q.isEmpty ||
            t.displayName.toLowerCase().contains(q) ||
            t.email.toLowerCase().contains(q))
          t,
    ];
  }

  @override
  Future<TeacherCreateResult> create({
    required String displayName,
    required String email,
    String? tempPassword,
  }) async {
    if (alwaysFail) throw StateError('Create teacher failed');
    final name = displayName.trim();
    final mail = email.trim().toLowerCase();
    if (name.isEmpty) throw StateError('Display name is required.');
    if (!mail.contains('@')) throw StateError('A valid email is required.');
    if (_teachers.any((t) => t.email == mail)) {
      throw StateError('Email already registered.');
    }
    createCount++;
    final teacher = SchoolTeacher(
      id: 'teacher-${_teachers.length + 1}',
      displayName: name,
      email: mail,
      profileStatus: 'active',
      membershipStatus: 'active',
    );
    _teachers.add(teacher);
    return TeacherCreateResult(
      teacher: teacher,
      tempPassword: tempPassword?.trim().isNotEmpty == true
          ? tempPassword!.trim()
          : 'NanoTeachTemp1!',
      teachers: List.of(_teachers),
    );
  }

  @override
  Future<List<SchoolTeacher>> setStatus({
    required String userId,
    required String status,
    required String reason,
  }) async {
    if (alwaysFail) throw StateError('Status update failed');
    if (reason.trim().isEmpty) throw StateError('A reason is required.');
    if (status != 'active' && status != 'suspended') {
      throw StateError('Only active or suspended is allowed.');
    }
    final index = _teachers.indexWhere((t) => t.id == userId);
    if (index < 0) throw StateError('Teacher not found in this school.');
    statusReasons.add(reason.trim());
    final current = _teachers[index];
    _teachers[index] = SchoolTeacher(
      id: current.id,
      displayName: current.displayName,
      email: current.email,
      profileStatus: status,
      membershipStatus: status,
    );
    return List.of(_teachers);
  }

  @override
  Future<TeacherImportPreview> previewImport(
    List<Map<String, String>> rows,
  ) async {
    if (alwaysFail) throw StateError('Import preview failed');
    final ok = <TeacherImportRow>[];
    final fail = <TeacherImportFailure>[];
    final seen = <String>{};
    for (var i = 0; i < rows.length; i++) {
      final name = (rows[i]['display_name'] ?? '').trim();
      final email = (rows[i]['email'] ?? '').trim().toLowerCase();
      final rowNum = i + 1;
      if (name.isEmpty || email.isEmpty) {
        fail.add(TeacherImportFailure(
          row: rowNum,
          email: email,
          error: 'display_name and email are required',
        ));
        continue;
      }
      if (!email.contains('@')) {
        fail.add(TeacherImportFailure(
          row: rowNum,
          email: email,
          error: 'invalid email',
        ));
        continue;
      }
      if (seen.contains(email)) {
        fail.add(TeacherImportFailure(
          row: rowNum,
          email: email,
          error: 'duplicate in file',
        ));
        continue;
      }
      if (_teachers.any((t) => t.email == email)) {
        fail.add(TeacherImportFailure(
          row: rowNum,
          email: email,
          error: 'email already registered',
        ));
        continue;
      }
      seen.add(email);
      ok.add(TeacherImportRow(row: rowNum, displayName: name, email: email));
    }
    return TeacherImportPreview(
      okCount: ok.length,
      failCount: fail.length,
      okRows: ok,
      failedRows: fail,
    );
  }

  @override
  Future<TeacherImportCommitResult> commitImport(
    List<Map<String, String>> rows,
  ) async {
    final preview = await previewImport(rows);
    if (!preview.canCommit) {
      return TeacherImportCommitResult(
        committed: false,
        message: 'Fix failed rows before commit. Nothing was written.',
        preview: preview,
        created: const [],
        teachers: List.of(_teachers),
      );
    }
    final created = <Map<String, dynamic>>[];
    for (final row in preview.okRows) {
      final result = await create(
        displayName: row.displayName,
        email: row.email,
      );
      created.add({
        'email': row.email,
        'display_name': row.displayName,
        'id': result.teacher.id,
        'temp_password': result.tempPassword,
      });
    }
    return TeacherImportCommitResult(
      committed: true,
      message: 'Import committed.',
      preview: preview,
      created: created,
      teachers: List.of(_teachers),
    );
  }
}

class SupabaseSchoolTeacherRepository implements SchoolTeacherRepository {
  SupabaseSchoolTeacherRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<SchoolTeacher>> list({String query = ''}) async {
    final raw = await _client.rpc(
      'list_school_teachers',
      params: {'p_query': query},
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        SchoolTeacher.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<TeacherCreateResult> create({
    required String displayName,
    required String email,
    String? tempPassword,
  }) async {
    final raw = await _client.rpc(
      'create_school_teacher',
      params: {
        'p_display_name': displayName,
        'p_email': email,
        'p_temp_password': tempPassword,
      },
    );
    if (raw is! Map) throw StateError('Create teacher failed.');
    return TeacherCreateResult.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<List<SchoolTeacher>> setStatus({
    required String userId,
    required String status,
    required String reason,
  }) async {
    final raw = await _client.rpc(
      'set_school_teacher_status',
      params: {
        'p_user_id': userId,
        'p_status': status,
        'p_reason': reason,
      },
    );
    if (raw is! List) return const [];
    return [
      for (final row in raw.whereType<Map>())
        SchoolTeacher.fromJson(Map<String, dynamic>.from(row)),
    ];
  }

  @override
  Future<TeacherImportPreview> previewImport(
    List<Map<String, String>> rows,
  ) async {
    final raw = await _client.rpc(
      'preview_teacher_import',
      params: {'p_rows': rows},
    );
    if (raw is! Map) throw StateError('Import preview failed.');
    return TeacherImportPreview.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherImportCommitResult> commitImport(
    List<Map<String, String>> rows,
  ) async {
    final raw = await _client.rpc(
      'commit_teacher_import',
      params: {'p_rows': rows},
    );
    if (raw is! Map) throw StateError('Import commit failed.');
    return TeacherImportCommitResult.fromJson(Map<String, dynamic>.from(raw));
  }
}
