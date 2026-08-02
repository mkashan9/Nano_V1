import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'teacher_classes_repository.dart';

/// ATT-01 attendance grid load + submit.
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
}

class FakeTeacherAttendanceRepository implements TeacherAttendanceRepository {
  FakeTeacherAttendanceRepository({
    TeacherClassesRepository? classesRepository,
  }) : _classes = classesRepository ?? FakeTeacherClassesRepository();

  final TeacherClassesRepository _classes;
  final Map<String, TeacherAttendanceGrid> _grids = {};
  var alwaysFail = false;

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
}
