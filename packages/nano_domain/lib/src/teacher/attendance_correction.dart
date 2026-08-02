import 'teacher_attendance.dart';

/// ATT-03 attendance correction and history models.
class AttendanceCorrectionRecord {
  const AttendanceCorrectionRecord({
    required this.id,
    required this.sessionId,
    required this.studentUserId,
    required this.displayName,
    required this.previousStatus,
    required this.newStatus,
    required this.reason,
    required this.correctedBy,
    required this.correctedByName,
    required this.correctedAt,
    required this.revisionBefore,
    required this.revisionAfter,
  });

  final String id;
  final String sessionId;
  final String studentUserId;
  final String displayName;
  final AttendanceEntryStatus previousStatus;
  final AttendanceEntryStatus newStatus;
  final String reason;
  final String correctedBy;
  final String correctedByName;
  final DateTime? correctedAt;
  final int revisionBefore;
  final int revisionAfter;

  factory AttendanceCorrectionRecord.fromJson(Map<String, dynamic> json) {
    return AttendanceCorrectionRecord(
      id: json['id'] as String? ?? '',
      sessionId: json['session_id'] as String? ?? '',
      studentUserId: json['student_user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      previousStatus:
          AttendanceEntryStatus.parse(json['previous_status'] as String?),
      newStatus: AttendanceEntryStatus.parse(json['new_status'] as String?),
      reason: json['reason'] as String? ?? '',
      correctedBy: json['corrected_by'] as String? ?? '',
      correctedByName: json['corrected_by_name'] as String? ?? '',
      correctedAt: json['corrected_at'] == null
          ? null
          : DateTime.tryParse('${json['corrected_at']}'),
      revisionBefore: (json['revision_before'] as num?)?.toInt() ?? 0,
      revisionAfter: (json['revision_after'] as num?)?.toInt() ?? 0,
    );
  }
}

class AttendanceCorrectionHistory {
  const AttendanceCorrectionHistory({
    required this.assignmentId,
    required this.sessionDate,
    required this.periodKey,
    required this.corrections,
    this.sessionId,
    this.generatedAt,
  });

  final String assignmentId;
  final String? sessionId;
  final String sessionDate;
  final String periodKey;
  final List<AttendanceCorrectionRecord> corrections;
  final DateTime? generatedAt;

  factory AttendanceCorrectionHistory.fromJson(Map<String, dynamic> json) {
    final rows = json['corrections'];
    return AttendanceCorrectionHistory(
      assignmentId: json['assignment_id'] as String? ?? '',
      sessionId: json['session_id'] as String?,
      sessionDate: '${json['session_date'] ?? ''}',
      periodKey: json['period_key'] as String? ?? 'daily',
      corrections: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            AttendanceCorrectionRecord.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class AttendanceCorrectionResult {
  const AttendanceCorrectionResult({
    required this.corrected,
    required this.correctionId,
    required this.grid,
    required this.history,
  });

  final bool corrected;
  final String correctionId;
  final TeacherAttendanceGrid grid;
  final AttendanceCorrectionHistory history;

  factory AttendanceCorrectionResult.fromJson(Map<String, dynamic> json) {
    final gridRaw = json['grid'];
    final historyRaw = json['history'];
    if (gridRaw is! Map || historyRaw is! Map) {
      throw FormatException('Attendance correction result incomplete.');
    }
    return AttendanceCorrectionResult(
      corrected: json['corrected'] as bool? ?? false,
      correctionId: json['correction_id'] as String? ?? '',
      grid: TeacherAttendanceGrid.fromJson(Map<String, dynamic>.from(gridRaw)),
      history: AttendanceCorrectionHistory.fromJson(
        Map<String, dynamic>.from(historyRaw),
      ),
    );
  }
}
