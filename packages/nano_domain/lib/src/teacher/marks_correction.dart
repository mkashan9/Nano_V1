import 'teacher_marks_grid.dart';

/// MRK-04 marks correction and publication history models.
class MarksCorrectionRecord {
  const MarksCorrectionRecord({
    required this.id,
    required this.assessmentId,
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
    this.previousObtainedMarks,
    this.newObtainedMarks,
    this.previousRemarks = '',
    this.newRemarks = '',
  });

  final String id;
  final String assessmentId;
  final String studentUserId;
  final String displayName;
  final MarksEntryStatus previousStatus;
  final MarksEntryStatus newStatus;
  final double? previousObtainedMarks;
  final double? newObtainedMarks;
  final String previousRemarks;
  final String newRemarks;
  final String reason;
  final String correctedBy;
  final String correctedByName;
  final DateTime? correctedAt;
  final int revisionBefore;
  final int revisionAfter;

  factory MarksCorrectionRecord.fromJson(Map<String, dynamic> json) {
    return MarksCorrectionRecord(
      id: json['id'] as String? ?? '',
      assessmentId: json['assessment_id'] as String? ?? '',
      studentUserId: json['student_user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      previousStatus:
          MarksEntryStatus.parse(json['previous_status'] as String?),
      newStatus: MarksEntryStatus.parse(json['new_status'] as String?),
      previousObtainedMarks:
          (json['previous_obtained_marks'] as num?)?.toDouble(),
      newObtainedMarks: (json['new_obtained_marks'] as num?)?.toDouble(),
      previousRemarks: json['previous_remarks'] as String? ?? '',
      newRemarks: json['new_remarks'] as String? ?? '',
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

class MarksCorrectionHistory {
  const MarksCorrectionHistory({
    required this.assessmentId,
    required this.corrections,
    this.generatedAt,
  });

  final String assessmentId;
  final List<MarksCorrectionRecord> corrections;
  final DateTime? generatedAt;

  factory MarksCorrectionHistory.fromJson(Map<String, dynamic> json) {
    final rows = json['corrections'];
    return MarksCorrectionHistory(
      assessmentId: json['assessment_id'] as String? ?? '',
      corrections: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            MarksCorrectionRecord.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

class MarksCorrectionResult {
  const MarksCorrectionResult({
    required this.corrected,
    required this.correctionId,
    required this.grid,
    required this.history,
  });

  final bool corrected;
  final String correctionId;
  final TeacherMarksGrid grid;
  final MarksCorrectionHistory history;

  factory MarksCorrectionResult.fromJson(Map<String, dynamic> json) {
    final gridRaw = json['grid'];
    final historyRaw = json['history'];
    if (gridRaw is! Map || historyRaw is! Map) {
      throw FormatException('Marks correction result incomplete.');
    }
    return MarksCorrectionResult(
      corrected: json['corrected'] as bool? ?? false,
      correctionId: json['correction_id'] as String? ?? '',
      grid: TeacherMarksGrid.fromJson(Map<String, dynamic>.from(gridRaw)),
      history: MarksCorrectionHistory.fromJson(
        Map<String, dynamic>.from(historyRaw),
      ),
    );
  }
}
