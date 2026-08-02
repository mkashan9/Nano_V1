import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// FLX-02 student read-only attendance (own submitted rows only).
abstract class StudentAttendanceRepository {
  Future<StudentAttendanceSummary> loadMine({
    required DateTime from,
    required DateTime to,
  });
}

class FakeStudentAttendanceRepository implements StudentAttendanceRepository {
  FakeStudentAttendanceRepository({
    List<StudentAttendanceDay>? seed,
    this.alwaysFail = false,
  }) : _seed = seed ??
            [
              StudentAttendanceDay(
                sessionDate: DateTime.utc(2026, 8, 1),
                status: AttendanceEntryStatus.present,
                subjectCode: 'MATH',
                classLabel: '5-A',
              ),
              StudentAttendanceDay(
                sessionDate: DateTime.utc(2026, 8, 2),
                status: AttendanceEntryStatus.late,
                subjectCode: 'MATH',
                classLabel: '5-A',
              ),
              StudentAttendanceDay(
                sessionDate: DateTime.utc(2026, 7, 31),
                status: AttendanceEntryStatus.absent,
                subjectCode: 'ENG',
                classLabel: '5-A',
              ),
            ];

  final List<StudentAttendanceDay> _seed;
  var alwaysFail;

  @override
  Future<StudentAttendanceSummary> loadMine({
    required DateTime from,
    required DateTime to,
  }) async {
    if (alwaysFail) throw StateError('Attendance unavailable');
    final fromDay = DateTime.utc(from.year, from.month, from.day);
    final toDay = DateTime.utc(to.year, to.month, to.day);
    final days = [
      for (final d in _seed)
        if (!d.sessionDate.isBefore(fromDay) && !d.sessionDate.isAfter(toDay)) d,
    ]..sort((a, b) => b.sessionDate.compareTo(a.sessionDate));

    var present = 0, absent = 0, late = 0, leave = 0, excused = 0;
    for (final d in days) {
      switch (d.status) {
        case AttendanceEntryStatus.present:
          present++;
        case AttendanceEntryStatus.absent:
          absent++;
        case AttendanceEntryStatus.late:
          late++;
        case AttendanceEntryStatus.leave:
          leave++;
        case AttendanceEntryStatus.excused:
          excused++;
      }
    }
    return StudentAttendanceSummary(
      from: fromDay,
      to: toDay,
      days: List.unmodifiable(days),
      presentCount: present,
      absentCount: absent,
      lateCount: late,
      leaveCount: leave,
      excusedCount: excused,
      generatedAt: DateTime.utc(2026, 8, 2),
    );
  }
}

class SupabaseStudentAttendanceRepository
    implements StudentAttendanceRepository {
  SupabaseStudentAttendanceRepository(this._client);

  final SupabaseClient _client;

  String _isoDate(DateTime d) {
    final u = d.toUtc();
    final mm = u.month.toString().padLeft(2, '0');
    final dd = u.day.toString().padLeft(2, '0');
    return '${u.year}-$mm-$dd';
  }

  @override
  Future<StudentAttendanceSummary> loadMine({
    required DateTime from,
    required DateTime to,
  }) async {
    final raw = await _client.rpc(
      'student_attendance_mine',
      params: {
        'p_from': _isoDate(from),
        'p_to': _isoDate(to),
      },
    );
    if (raw is! Map) throw StateError('Attendance unavailable.');
    return StudentAttendanceSummary.fromJson(Map<String, dynamic>.from(raw));
  }
}
