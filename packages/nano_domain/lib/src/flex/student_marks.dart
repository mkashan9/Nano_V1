import '../teacher/teacher_assessment.dart';
import '../teacher/teacher_marks_grid.dart';

export '../teacher/teacher_assessment.dart' show AssessmentStatus;
export '../teacher/teacher_marks_grid.dart' show MarksEntryStatus;

/// FLX-03 one published/corrected assessment result for the signed-in student.
class StudentMarksResult {
  const StudentMarksResult({
    required this.assessmentId,
    required this.entryId,
    required this.name,
    required this.category,
    required this.assessmentDate,
    required this.assessmentStatus,
    required this.entryStatus,
    required this.totalMarks,
    this.obtainedMarks,
    this.remarks = '',
    this.subjectCode,
    this.classLabel,
    this.publishedAt,
    this.revision = 1,
    this.correctionCount = 0,
    this.lastCorrectedAt,
  });

  final String assessmentId;
  final String entryId;
  final String name;
  final String category;
  final DateTime assessmentDate;
  final AssessmentStatus assessmentStatus;
  final MarksEntryStatus entryStatus;
  final double totalMarks;
  final double? obtainedMarks;
  final String remarks;
  final String? subjectCode;
  final String? classLabel;
  final DateTime? publishedAt;
  final int revision;
  final int correctionCount;
  final DateTime? lastCorrectedAt;

  String get dateIso {
    final d = assessmentDate.toUtc();
    final mm = d.month.toString().padLeft(2, '0');
    final dd = d.day.toString().padLeft(2, '0');
    return '${d.year}-$mm-$dd';
  }

  bool get wasCorrected =>
      correctionCount > 0 || assessmentStatus == AssessmentStatus.corrected;

  factory StudentMarksResult.fromJson(Map<String, dynamic> json) {
    final rawDate = json['assessment_date']?.toString() ?? '';
    return StudentMarksResult(
      assessmentId: json['assessment_id'] as String? ?? '',
      entryId: json['entry_id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      category: json['category'] as String? ?? '',
      assessmentDate:
          DateTime.tryParse(rawDate)?.toUtc() ?? DateTime.utc(1970),
      assessmentStatus:
          AssessmentStatus.parse(json['assessment_status'] as String?),
      entryStatus: MarksEntryStatus.parse(json['status'] as String?),
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
      obtainedMarks: (json['obtained_marks'] as num?)?.toDouble(),
      remarks: json['remarks'] as String? ?? '',
      subjectCode: json['subject_code'] as String?,
      classLabel: json['class_label'] as String?,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.tryParse('${json['published_at']}'),
      revision: (json['revision'] as num?)?.toInt() ?? 1,
      correctionCount: (json['correction_count'] as num?)?.toInt() ?? 0,
      lastCorrectedAt: json['last_corrected_at'] == null
          ? null
          : DateTime.tryParse('${json['last_corrected_at']}'),
    );
  }
}

/// Month (or range) summary of the student's published marks.
class StudentMarksSummary {
  const StudentMarksSummary({
    required this.from,
    required this.to,
    required this.results,
    this.scoredCount = 0,
    this.absentCount = 0,
    this.exemptCount = 0,
    this.notSubmittedCount = 0,
    this.generatedAt,
  });

  final DateTime from;
  final DateTime to;
  final List<StudentMarksResult> results;
  final int scoredCount;
  final int absentCount;
  final int exemptCount;
  final int notSubmittedCount;
  final DateTime? generatedAt;

  int get recordedCount => results.length;

  factory StudentMarksSummary.fromJson(Map<String, dynamic> json) {
    final rows = json['results'];
    return StudentMarksSummary(
      from: DateTime.tryParse('${json['from']}')?.toUtc() ?? DateTime.utc(1970),
      to: DateTime.tryParse('${json['to']}')?.toUtc() ?? DateTime.utc(1970),
      results: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            StudentMarksResult.fromJson(Map<String, dynamic>.from(row)),
      ],
      scoredCount: (json['scored_count'] as num?)?.toInt() ?? 0,
      absentCount: (json['absent_count'] as num?)?.toInt() ?? 0,
      exemptCount: (json['exempt_count'] as num?)?.toInt() ?? 0,
      notSubmittedCount: (json['not_submitted_count'] as num?)?.toInt() ?? 0,
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}
