import '../teacher/teacher_attendance.dart';

export '../teacher/teacher_attendance.dart' show AttendanceEntryStatus;

/// FLX-02 one submitted attendance day for the signed-in student.
class StudentAttendanceDay {
  const StudentAttendanceDay({
    required this.sessionDate,
    required this.status,
    this.periodKey = 'daily',
    this.subjectCode,
    this.classLabel,
  });

  final DateTime sessionDate;
  final AttendanceEntryStatus status;
  final String periodKey;
  final String? subjectCode;
  final String? classLabel;

  String get dateIso {
    final d = sessionDate.toUtc();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  factory StudentAttendanceDay.fromJson(Map<String, dynamic> json) {
    final rawDate = json['session_date']?.toString() ?? '';
    return StudentAttendanceDay(
      sessionDate: DateTime.tryParse(rawDate)?.toUtc() ??
          DateTime.utc(1970),
      status: AttendanceEntryStatus.parse(json['status'] as String?),
      periodKey: json['period_key'] as String? ?? 'daily',
      subjectCode: json['subject_code'] as String?,
      classLabel: json['class_label'] as String?,
    );
  }
}

/// Month (or range) summary of the student's own submitted attendance.
class StudentAttendanceSummary {
  const StudentAttendanceSummary({
    required this.from,
    required this.to,
    required this.days,
    this.presentCount = 0,
    this.absentCount = 0,
    this.lateCount = 0,
    this.leaveCount = 0,
    this.excusedCount = 0,
    this.generatedAt,
  });

  final DateTime from;
  final DateTime to;
  final List<StudentAttendanceDay> days;
  final int presentCount;
  final int absentCount;
  final int lateCount;
  final int leaveCount;
  final int excusedCount;
  final DateTime? generatedAt;

  int get recordedDays => days.length;

  factory StudentAttendanceSummary.fromJson(Map<String, dynamic> json) {
    final rows = json['days'];
    return StudentAttendanceSummary(
      from: DateTime.tryParse('${json['from']}')?.toUtc() ?? DateTime.utc(1970),
      to: DateTime.tryParse('${json['to']}')?.toUtc() ?? DateTime.utc(1970),
      days: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            StudentAttendanceDay.fromJson(Map<String, dynamic>.from(row)),
      ],
      presentCount: (json['present_count'] as num?)?.toInt() ?? 0,
      absentCount: (json['absent_count'] as num?)?.toInt() ?? 0,
      lateCount: (json['late_count'] as num?)?.toInt() ?? 0,
      leaveCount: (json['leave_count'] as num?)?.toInt() ?? 0,
      excusedCount: (json['excused_count'] as num?)?.toInt() ?? 0,
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}
