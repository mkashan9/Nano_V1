import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'teacher_classes_repository.dart';

/// ATT-01/ATT-02/ATT-03 attendance grid, CSV import, and corrections.
abstract class TeacherAttendanceRepository {
  Future<TeacherMyClasses> listAssignments();
  Future<TeacherAttendanceGrid> load({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  });
  Future<TeacherAttendanceGrid> submit({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<AttendanceEntryMark> entries,
    String periodKey = 'daily',
  });
  Future<AttendanceImportTemplate> loadTemplate({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  });
  Future<AttendanceImportPreview> previewImport({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
    String periodKey = 'daily',
  });
  Future<AttendanceImportCommitResult> commitImport({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
    String periodKey = 'daily',
  });
  Future<AttendanceCorrectionHistory> loadHistory({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  });
  Future<AttendanceCorrectionResult> correct({
    required String assignmentId,
    required String sessionDate,
    required String studentUserId,
    required AttendanceEntryStatus newStatus,
    required String reason,
    String periodKey = 'daily',
  });
}

class FakeTeacherAttendanceRepository implements TeacherAttendanceRepository {
  FakeTeacherAttendanceRepository({
    TeacherClassesRepository? classesRepository,
  }) : _classes = classesRepository ?? FakeTeacherClassesRepository();

  final TeacherClassesRepository _classes;
  final Map<String, TeacherAttendanceGrid> _grids = {};
  final Map<String, List<AttendanceCorrectionRecord>> _history = {};
  var alwaysFail = false;
  var _correctionSeq = 0;

  String _key(String assignmentId, String date, String period) =>
      '$assignmentId|$date|$period';

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

  @override
  Future<TeacherAttendanceGrid> load({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  }) async {
    if (alwaysFail) throw StateError('Attendance unavailable');
    final mine = await _classes.listMine();
    TeacherAssignmentScope? scope;
    for (final a in mine.assignments) {
      if (a.id == assignmentId) {
        scope = a;
        break;
      }
    }
    if (scope == null) {
      throw StateError('Assignment is not in your active scope.');
    }
    final existing = _grids[_key(assignmentId, sessionDate, periodKey)];
    if (existing != null) return existing;

    final roster = await _classes.loadRoster(assignmentId);
    return TeacherAttendanceGrid(
      assignmentId: assignmentId,
      schoolId: mine.schoolId,
      sessionDate: sessionDate,
      periodKey: periodKey,
      attendanceMode: 'daily',
      classLabel: scope.classLabel,
      subjectCode: scope.subjectCode,
      roster: [
        for (final s in roster.students)
          AttendanceRosterStudent(id: s.id, displayName: s.displayName),
      ],
      entries: const [],
    );
  }

  @override
  Future<TeacherAttendanceGrid> submit({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<AttendanceEntryMark> entries,
    String periodKey = 'daily',
  }) async {
    if (alwaysFail) throw StateError('Attendance unavailable');
    final key = _key(assignmentId, sessionDate, periodKey);
    final existing = _grids[key];
    if (existing?.session?.idempotencyKey == idempotencyKey) {
      return existing!;
    }
    if (existing?.isSubmitted ?? false) {
      throw StateError('Attendance already submitted for this scope and date.');
    }
    final base = await load(
      assignmentId: assignmentId,
      sessionDate: sessionDate,
      periodKey: periodKey,
    );
    final rosterIds = {for (final s in base.roster) s.id};
    for (final e in entries) {
      if (!rosterIds.contains(e.studentUserId)) {
        throw StateError('Student is not on the assigned roster.');
      }
    }
    final submitted = TeacherAttendanceGrid(
      assignmentId: base.assignmentId,
      schoolId: base.schoolId,
      sessionDate: base.sessionDate,
      periodKey: base.periodKey,
      attendanceMode: base.attendanceMode,
      classLabel: base.classLabel,
      subjectCode: base.subjectCode,
      roster: base.roster,
      entries: entries,
      session: AttendanceSessionInfo(
        id: 'sess-$assignmentId',
        status: 'submitted',
        revision: (existing?.session?.revision ?? 0) + 1,
        idempotencyKey: idempotencyKey,
        submittedAt: DateTime.utc(2026, 8, 2),
      ),
      generatedAt: DateTime.utc(2026, 8, 2),
    );
    _grids[key] = submitted;
    return submitted;
  }

  @override
  Future<AttendanceImportTemplate> loadTemplate({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  }) async {
    final grid = await load(
      assignmentId: assignmentId,
      sessionDate: sessionDate,
      periodKey: periodKey,
    );
    return AttendanceImportTemplate(
      assignmentId: grid.assignmentId,
      sessionDate: grid.sessionDate,
      periodKey: grid.periodKey,
      classLabel: grid.classLabel,
      subjectCode: grid.subjectCode,
      headers: const ['student_user_id', 'display_name', 'status'],
      rows: [
        for (final s in grid.roster)
          {
            'student_user_id': s.id,
            'display_name': s.displayName,
            'status': (grid.statusByStudent[s.id] ?? AttendanceEntryStatus.present)
                .wire,
          },
      ],
    );
  }

  @override
  Future<AttendanceImportPreview> previewImport({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
    String periodKey = 'daily',
  }) async {
    if (alwaysFail) throw StateError('Attendance unavailable');
    final grid = await load(
      assignmentId: assignmentId,
      sessionDate: sessionDate,
      periodKey: periodKey,
    );
    if (grid.isSubmitted &&
        grid.session?.idempotencyKey != idempotencyKey) {
      throw StateError('Attendance already submitted for this scope and date.');
    }
    final rosterIds = {for (final s in grid.roster) s.id};
    final ok = <AttendanceImportOkRow>[];
    final fail = <AttendanceImportFailure>[];
    for (var i = 0; i < rows.length; i++) {
      final row = rows[i];
      final id = (row['student_user_id'] ?? '').trim();
      final status = (row['status'] ?? '').trim().toLowerCase();
      if (id.isEmpty || !rosterIds.contains(id)) {
        fail.add(AttendanceImportFailure(
          row: i + 1,
          studentUserId: id,
          error: 'student not on assigned roster',
        ));
        continue;
      }
      if (!{'present', 'absent', 'late', 'leave', 'excused'}.contains(status)) {
        fail.add(AttendanceImportFailure(
          row: i + 1,
          studentUserId: id,
          error: 'invalid status',
        ));
        continue;
      }
      ok.add(AttendanceImportOkRow(
        row: i + 1,
        studentUserId: id,
        status: status,
      ));
    }
    return AttendanceImportPreview(
      jobId: 'job-$assignmentId',
      assignmentId: assignmentId,
      sessionDate: sessionDate,
      periodKey: periodKey,
      okCount: ok.length,
      failCount: fail.length,
      okRows: ok,
      failedRows: fail,
      canCommit: fail.isEmpty && ok.isNotEmpty,
    );
  }

  @override
  Future<AttendanceImportCommitResult> commitImport({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
    String periodKey = 'daily',
  }) async {
    final preview = await previewImport(
      assignmentId: assignmentId,
      sessionDate: sessionDate,
      idempotencyKey: idempotencyKey,
      rows: rows,
      periodKey: periodKey,
    );
    if (!preview.canCommit) {
      throw StateError('Attendance import has validation errors.');
    }
    final grid = await submit(
      assignmentId: assignmentId,
      sessionDate: sessionDate,
      idempotencyKey: idempotencyKey,
      entries: [
        for (final r in preview.okRows)
          AttendanceEntryMark(
            studentUserId: r.studentUserId,
            status: AttendanceEntryStatus.parse(r.status),
          ),
      ],
      periodKey: periodKey,
    );
    return AttendanceImportCommitResult(
      committed: true,
      message: 'Attendance import committed.',
      preview: preview,
      grid: grid,
    );
  }

  @override
  Future<AttendanceCorrectionHistory> loadHistory({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  }) async {
    if (alwaysFail) throw StateError('Attendance unavailable');
    final key = _key(assignmentId, sessionDate, periodKey);
    final grid = _grids[key];
    return AttendanceCorrectionHistory(
      assignmentId: assignmentId,
      sessionId: grid?.session?.id,
      sessionDate: sessionDate,
      periodKey: periodKey,
      corrections: List.unmodifiable(_history[key] ?? const []),
      generatedAt: DateTime.utc(2026, 8, 2),
    );
  }

  @override
  Future<AttendanceCorrectionResult> correct({
    required String assignmentId,
    required String sessionDate,
    required String studentUserId,
    required AttendanceEntryStatus newStatus,
    required String reason,
    String periodKey = 'daily',
  }) async {
    if (alwaysFail) throw StateError('Attendance unavailable');
    final trimmed = reason.trim();
    if (trimmed.isEmpty) {
      throw StateError('Correction reason is required.');
    }
    final key = _key(assignmentId, sessionDate, periodKey);
    final existing = _grids[key];
    if (existing == null || !existing.isSubmitted) {
      throw StateError('Only submitted attendance can be corrected.');
    }
    final current = existing.statusByStudent[studentUserId];
    if (current == null) {
      throw StateError('Attendance entry not found for student.');
    }
    if (current == newStatus) {
      throw StateError('New status must differ from the current value.');
    }
    final revBefore = existing.session?.revision ?? 1;
    final revAfter = revBefore + 1;
    _correctionSeq += 1;
    String displayName = '';
    for (final s in existing.roster) {
      if (s.id == studentUserId) {
        displayName = s.displayName;
        break;
      }
    }
    final record = AttendanceCorrectionRecord(
      id: 'corr-$_correctionSeq',
      sessionId: existing.session!.id,
      studentUserId: studentUserId,
      displayName: displayName,
      previousStatus: current,
      newStatus: newStatus,
      reason: trimmed,
      correctedBy: 'teacher-1',
      correctedByName: 'Teacher',
      correctedAt: DateTime.utc(2026, 8, 2, 12, _correctionSeq),
      revisionBefore: revBefore,
      revisionAfter: revAfter,
    );
    final updatedEntries = [
      for (final e in existing.entries)
        if (e.studentUserId == studentUserId)
          AttendanceEntryMark(studentUserId: studentUserId, status: newStatus)
        else
          e,
    ];
    final grid = TeacherAttendanceGrid(
      assignmentId: existing.assignmentId,
      schoolId: existing.schoolId,
      sessionDate: existing.sessionDate,
      periodKey: existing.periodKey,
      attendanceMode: existing.attendanceMode,
      classLabel: existing.classLabel,
      subjectCode: existing.subjectCode,
      roster: existing.roster,
      entries: updatedEntries,
      session: AttendanceSessionInfo(
        id: existing.session!.id,
        status: existing.session!.status,
        revision: revAfter,
        idempotencyKey: existing.session!.idempotencyKey,
        submittedAt: existing.session!.submittedAt,
      ),
      generatedAt: DateTime.utc(2026, 8, 2),
    );
    _grids[key] = grid;
    _history[key] = [record, ...(_history[key] ?? const [])];
    final history = await loadHistory(
      assignmentId: assignmentId,
      sessionDate: sessionDate,
      periodKey: periodKey,
    );
    return AttendanceCorrectionResult(
      corrected: true,
      correctionId: record.id,
      grid: grid,
      history: history,
    );
  }
}

class SupabaseTeacherAttendanceRepository implements TeacherAttendanceRepository {
  SupabaseTeacherAttendanceRepository(this._client);

  final SupabaseClient _client;
  late final TeacherClassesRepository _classes =
      SupabaseTeacherClassesRepository(_client);

  @override
  Future<TeacherMyClasses> listAssignments() => _classes.listMine();

  @override
  Future<TeacherAttendanceGrid> load({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  }) async {
    final raw = await _client.rpc(
      'teacher_attendance_load',
      params: {
        'p_assignment_id': assignmentId,
        'p_session_date': sessionDate,
        'p_period_key': periodKey,
      },
    );
    if (raw is! Map) throw StateError('Attendance unavailable.');
    return TeacherAttendanceGrid.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<TeacherAttendanceGrid> submit({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<AttendanceEntryMark> entries,
    String periodKey = 'daily',
  }) async {
    final raw = await _client.rpc(
      'teacher_attendance_submit',
      params: {
        'p_assignment_id': assignmentId,
        'p_session_date': sessionDate,
        'p_idempotency_key': idempotencyKey,
        'p_entries': [for (final e in entries) e.toWire()],
        'p_period_key': periodKey,
      },
    );
    if (raw is! Map) throw StateError('Attendance submit failed.');
    return TeacherAttendanceGrid.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<AttendanceImportTemplate> loadTemplate({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  }) async {
    final raw = await _client.rpc(
      'teacher_attendance_template',
      params: {
        'p_assignment_id': assignmentId,
        'p_session_date': sessionDate,
        'p_period_key': periodKey,
      },
    );
    if (raw is! Map) throw StateError('Attendance template unavailable.');
    return AttendanceImportTemplate.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<AttendanceImportPreview> previewImport({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
    String periodKey = 'daily',
  }) async {
    final raw = await _client.rpc(
      'preview_attendance_import',
      params: {
        'p_assignment_id': assignmentId,
        'p_session_date': sessionDate,
        'p_idempotency_key': idempotencyKey,
        'p_rows': rows,
        'p_period_key': periodKey,
      },
    );
    if (raw is! Map) throw StateError('Attendance import preview failed.');
    return AttendanceImportPreview.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<AttendanceImportCommitResult> commitImport({
    required String assignmentId,
    required String sessionDate,
    required String idempotencyKey,
    required List<Map<String, String>> rows,
    String periodKey = 'daily',
  }) async {
    final raw = await _client.rpc(
      'commit_attendance_import',
      params: {
        'p_assignment_id': assignmentId,
        'p_session_date': sessionDate,
        'p_idempotency_key': idempotencyKey,
        'p_rows': rows,
        'p_period_key': periodKey,
      },
    );
    if (raw is! Map) throw StateError('Attendance import commit failed.');
    return AttendanceImportCommitResult.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<AttendanceCorrectionHistory> loadHistory({
    required String assignmentId,
    required String sessionDate,
    String periodKey = 'daily',
  }) async {
    final raw = await _client.rpc(
      'teacher_attendance_history',
      params: {
        'p_assignment_id': assignmentId,
        'p_session_date': sessionDate,
        'p_period_key': periodKey,
      },
    );
    if (raw is! Map) throw StateError('Attendance history unavailable.');
    return AttendanceCorrectionHistory.fromJson(Map<String, dynamic>.from(raw));
  }

  @override
  Future<AttendanceCorrectionResult> correct({
    required String assignmentId,
    required String sessionDate,
    required String studentUserId,
    required AttendanceEntryStatus newStatus,
    required String reason,
    String periodKey = 'daily',
  }) async {
    final raw = await _client.rpc(
      'teacher_attendance_correct',
      params: {
        'p_assignment_id': assignmentId,
        'p_session_date': sessionDate,
        'p_student_user_id': studentUserId,
        'p_new_status': newStatus.wire,
        'p_reason': reason,
        'p_period_key': periodKey,
      },
    );
    if (raw is! Map) throw StateError('Attendance correction failed.');
    return AttendanceCorrectionResult.fromJson(Map<String, dynamic>.from(raw));
  }
}
