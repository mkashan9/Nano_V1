/// ATT-01 attendance grid domain models.
enum AttendanceEntryStatus {
  present,
  absent,
  late,
  leave,
  excused;

  static AttendanceEntryStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'absent':
        return AttendanceEntryStatus.absent;
      case 'late':
        return AttendanceEntryStatus.late;
      case 'leave':
        return AttendanceEntryStatus.leave;
      case 'excused':
        return AttendanceEntryStatus.excused;
      case 'present':
      default:
        return AttendanceEntryStatus.present;
    }
  }

  String get wire => name;

  AttendanceEntryStatus get next => switch (this) {
        AttendanceEntryStatus.present => AttendanceEntryStatus.absent,
        AttendanceEntryStatus.absent => AttendanceEntryStatus.late,
        AttendanceEntryStatus.late => AttendanceEntryStatus.leave,
        AttendanceEntryStatus.leave => AttendanceEntryStatus.excused,
        AttendanceEntryStatus.excused => AttendanceEntryStatus.present,
      };
}

class AttendanceRosterStudent {
  const AttendanceRosterStudent({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory AttendanceRosterStudent.fromJson(Map<String, dynamic> json) {
    return AttendanceRosterStudent(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }
}

class AttendanceEntryMark {
  const AttendanceEntryMark({
    required this.studentUserId,
    required this.status,
  });

  final String studentUserId;
  final AttendanceEntryStatus status;

  Map<String, dynamic> toWire() => {
        'student_user_id': studentUserId,
        'status': status.wire,
      };

  factory AttendanceEntryMark.fromJson(Map<String, dynamic> json) {
    return AttendanceEntryMark(
      studentUserId: json['student_user_id'] as String? ?? '',
      status: AttendanceEntryStatus.parse(json['status'] as String?),
    );
  }
}

class AttendanceSessionInfo {
  const AttendanceSessionInfo({
    required this.id,
    required this.status,
    required this.revision,
    required this.idempotencyKey,
    this.submittedAt,
  });

  final String id;
  final String status;
  final int revision;
  final String idempotencyKey;
  final DateTime? submittedAt;

  bool get isSubmitted => status == 'submitted';

  factory AttendanceSessionInfo.fromJson(Map<String, dynamic> json) {
    return AttendanceSessionInfo(
      id: json['id'] as String? ?? '',
      status: json['status'] as String? ?? 'draft',
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      idempotencyKey: json['idempotency_key'] as String? ?? '',
      submittedAt: json['submitted_at'] == null
          ? null
          : DateTime.tryParse('${json['submitted_at']}'),
    );
  }
}

class TeacherAttendanceGrid {
  const TeacherAttendanceGrid({
    required this.assignmentId,
    required this.schoolId,
    required this.sessionDate,
    required this.periodKey,
    required this.attendanceMode,
    required this.classLabel,
    required this.subjectCode,
    required this.roster,
    required this.entries,
    this.session,
    this.generatedAt,
  });

  final String assignmentId;
  final String schoolId;
  final String sessionDate;
  final String periodKey;
  final String attendanceMode;
  final String classLabel;
  final String subjectCode;
  final List<AttendanceRosterStudent> roster;
  final List<AttendanceEntryMark> entries;
  final AttendanceSessionInfo? session;
  final DateTime? generatedAt;

  bool get isSubmitted => session?.isSubmitted ?? false;

  String get scopeLabel => '$classLabel · $subjectCode';

  Map<String, AttendanceEntryStatus> get statusByStudent {
    return {
      for (final e in entries) e.studentUserId: e.status,
    };
  }

  factory TeacherAttendanceGrid.fromJson(Map<String, dynamic> json) {
    final rosterRaw = json['roster'];
    final entriesRaw = json['entries'];
    final sessionRaw = json['session'];
    return TeacherAttendanceGrid(
      assignmentId: json['assignment_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      sessionDate: '${json['session_date'] ?? ''}',
      periodKey: json['period_key'] as String? ?? 'daily',
      attendanceMode: json['attendance_mode'] as String? ?? 'daily',
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      roster: [
        if (rosterRaw is List)
          for (final row in rosterRaw.whereType<Map>())
            AttendanceRosterStudent.fromJson(Map<String, dynamic>.from(row)),
      ],
      entries: [
        if (entriesRaw is List)
          for (final row in entriesRaw.whereType<Map>())
            AttendanceEntryMark.fromJson(Map<String, dynamic>.from(row)),
      ],
      session: sessionRaw is Map
          ? AttendanceSessionInfo.fromJson(Map<String, dynamic>.from(sessionRaw))
          : null,
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}
