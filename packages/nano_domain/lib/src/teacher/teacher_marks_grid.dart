import 'teacher_assessment.dart';

/// MRK-02 in-app marks grid domain models.
enum MarksEntryStatus {
  scored,
  absent,
  exempt,
  notSubmitted;

  static MarksEntryStatus parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'absent':
        return MarksEntryStatus.absent;
      case 'exempt':
        return MarksEntryStatus.exempt;
      case 'not_submitted':
      case 'notsubmitted':
        return MarksEntryStatus.notSubmitted;
      case 'scored':
      default:
        return MarksEntryStatus.scored;
    }
  }

  String get wire => switch (this) {
        MarksEntryStatus.notSubmitted => 'not_submitted',
        _ => name,
      };

  MarksEntryStatus get next => switch (this) {
        MarksEntryStatus.scored => MarksEntryStatus.absent,
        MarksEntryStatus.absent => MarksEntryStatus.exempt,
        MarksEntryStatus.exempt => MarksEntryStatus.notSubmitted,
        MarksEntryStatus.notSubmitted => MarksEntryStatus.scored,
      };
}

class MarksRosterStudent {
  const MarksRosterStudent({
    required this.id,
    required this.displayName,
  });

  final String id;
  final String displayName;

  factory MarksRosterStudent.fromJson(Map<String, dynamic> json) {
    return MarksRosterStudent(
      id: json['id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
    );
  }
}

class MarksEntryMark {
  const MarksEntryMark({
    required this.studentUserId,
    required this.status,
    this.obtainedMarks,
    this.remarks = '',
  });

  final String studentUserId;
  final MarksEntryStatus status;
  final double? obtainedMarks;
  final String remarks;

  Map<String, dynamic> toWire() => {
        'student_user_id': studentUserId,
        'status': status.wire,
        'obtained_marks': status == MarksEntryStatus.scored ? obtainedMarks : null,
        'remarks': remarks,
      };

  factory MarksEntryMark.fromJson(Map<String, dynamic> json) {
    return MarksEntryMark(
      studentUserId: json['student_user_id'] as String? ?? '',
      status: MarksEntryStatus.parse(json['status'] as String?),
      obtainedMarks: (json['obtained_marks'] as num?)?.toDouble(),
      remarks: json['remarks'] as String? ?? '',
    );
  }
}

class TeacherMarksGrid {
  const TeacherMarksGrid({
    required this.assessmentId,
    required this.assignmentId,
    required this.schoolId,
    required this.assessmentName,
    required this.category,
    required this.assessmentDate,
    required this.totalMarks,
    required this.assessmentStatus,
    required this.allowBonus,
    required this.classLabel,
    required this.subjectCode,
    required this.roster,
    required this.entries,
    this.generatedAt,
  });

  final String assessmentId;
  final String assignmentId;
  final String schoolId;
  final String assessmentName;
  final String category;
  final String assessmentDate;
  final double totalMarks;
  final AssessmentStatus assessmentStatus;
  final bool allowBonus;
  final String classLabel;
  final String subjectCode;
  final List<MarksRosterStudent> roster;
  final List<MarksEntryMark> entries;
  final DateTime? generatedAt;

  bool get isDraft => assessmentStatus.isDraft;

  bool get isCorrectable => assessmentStatus.isCorrectable;

  String get scopeLabel => '$classLabel · $subjectCode';

  Map<String, MarksEntryMark> get entryByStudent {
    return {for (final e in entries) e.studentUserId: e};
  }

  factory TeacherMarksGrid.fromJson(Map<String, dynamic> json) {
    final rosterRaw = json['roster'];
    final entriesRaw = json['entries'];
    return TeacherMarksGrid(
      assessmentId: json['assessment_id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      assessmentName: json['assessment_name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      assessmentDate: '${json['assessment_date'] ?? ''}',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
      assessmentStatus:
          AssessmentStatus.parse(json['assessment_status'] as String?),
      allowBonus: json['allow_bonus'] as bool? ?? false,
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      roster: [
        if (rosterRaw is List)
          for (final row in rosterRaw.whereType<Map>())
            MarksRosterStudent.fromJson(Map<String, dynamic>.from(row)),
      ],
      entries: [
        if (entriesRaw is List)
          for (final row in entriesRaw.whereType<Map>())
            MarksEntryMark.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}
