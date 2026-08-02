/// MRK-05 result / class performance summary models.
class MarksGradeBucket {
  const MarksGradeBucket({
    required this.label,
    required this.count,
  });

  final String label;
  final int count;

  factory MarksGradeBucket.fromJson(Map<String, dynamic> json) {
    return MarksGradeBucket(
      label: json['label'] as String? ?? '',
      count: (json['count'] as num?)?.toInt() ?? 0,
    );
  }
}

class MarksResultStudentRow {
  const MarksResultStudentRow({
    required this.studentUserId,
    required this.displayName,
    required this.status,
    this.obtainedMarks,
    this.percent,
    this.passed,
    this.gradeLabel,
  });

  final String studentUserId;
  final String displayName;
  final String status;
  final double? obtainedMarks;
  final double? percent;
  final bool? passed;
  final String? gradeLabel;

  factory MarksResultStudentRow.fromJson(Map<String, dynamic> json) {
    return MarksResultStudentRow(
      studentUserId: json['student_user_id'] as String? ?? '',
      displayName: json['display_name'] as String? ?? '',
      status: json['status'] as String? ?? 'not_submitted',
      obtainedMarks: (json['obtained_marks'] as num?)?.toDouble(),
      percent: (json['percent'] as num?)?.toDouble(),
      passed: json['passed'] as bool?,
      gradeLabel: json['grade_label'] as String?,
    );
  }
}

class MarksResultSummary {
  const MarksResultSummary({
    required this.assessmentId,
    required this.assignmentId,
    required this.schoolId,
    required this.classLabel,
    required this.subjectCode,
    required this.assessmentName,
    required this.assessmentStatus,
    required this.totalMarks,
    required this.passingPercent,
    required this.reportCardFormat,
    required this.rosterCount,
    required this.scoredCount,
    required this.absentCount,
    required this.exemptCount,
    required this.notSubmittedCount,
    required this.averagePercent,
    required this.passCount,
    required this.failCount,
    required this.gradeDistribution,
    required this.students,
    this.resultPeriodId,
    this.resultPeriodName,
    this.medianPercent,
    this.highestPercent,
    this.lowestPercent,
    this.passRatePercent,
    this.generatedAt,
  });

  final String assessmentId;
  final String assignmentId;
  final String schoolId;
  final String classLabel;
  final String subjectCode;
  final String assessmentName;
  final String assessmentStatus;
  final double totalMarks;
  final String? resultPeriodId;
  final String? resultPeriodName;
  final double passingPercent;
  final String reportCardFormat;
  final int rosterCount;
  final int scoredCount;
  final int absentCount;
  final int exemptCount;
  final int notSubmittedCount;
  final double averagePercent;
  final double? medianPercent;
  final double? highestPercent;
  final double? lowestPercent;
  final int passCount;
  final int failCount;
  final double? passRatePercent;
  final List<MarksGradeBucket> gradeDistribution;
  final List<MarksResultStudentRow> students;
  final DateTime? generatedAt;

  String get scopeLabel => '$classLabel · $subjectCode';

  factory MarksResultSummary.fromJson(Map<String, dynamic> json) {
    final gradesRaw = json['grade_distribution'];
    final studentsRaw = json['students'];
    return MarksResultSummary(
      assessmentId: json['assessment_id'] as String? ?? '',
      assignmentId: json['assignment_id'] as String? ?? '',
      schoolId: json['school_id'] as String? ?? '',
      classLabel: json['class_label'] as String? ?? '',
      subjectCode: json['subject_code'] as String? ?? '',
      assessmentName: json['assessment_name'] as String? ?? '',
      assessmentStatus: json['assessment_status'] as String? ?? '',
      totalMarks: (json['total_marks'] as num?)?.toDouble() ?? 0,
      resultPeriodId: json['result_period_id'] as String?,
      resultPeriodName: json['result_period_name'] as String?,
      passingPercent: (json['passing_percent'] as num?)?.toDouble() ?? 40,
      reportCardFormat: json['report_card_format'] as String? ?? 'both',
      rosterCount: (json['roster_count'] as num?)?.toInt() ?? 0,
      scoredCount: (json['scored_count'] as num?)?.toInt() ?? 0,
      absentCount: (json['absent_count'] as num?)?.toInt() ?? 0,
      exemptCount: (json['exempt_count'] as num?)?.toInt() ?? 0,
      notSubmittedCount: (json['not_submitted_count'] as num?)?.toInt() ?? 0,
      averagePercent: (json['average_percent'] as num?)?.toDouble() ?? 0,
      medianPercent: (json['median_percent'] as num?)?.toDouble(),
      highestPercent: (json['highest_percent'] as num?)?.toDouble(),
      lowestPercent: (json['lowest_percent'] as num?)?.toDouble(),
      passCount: (json['pass_count'] as num?)?.toInt() ?? 0,
      failCount: (json['fail_count'] as num?)?.toInt() ?? 0,
      passRatePercent: (json['pass_rate_percent'] as num?)?.toDouble(),
      gradeDistribution: [
        if (gradesRaw is List)
          for (final row in gradesRaw.whereType<Map>())
            MarksGradeBucket.fromJson(Map<String, dynamic>.from(row)),
      ],
      students: [
        if (studentsRaw is List)
          for (final row in studentsRaw.whereType<Map>())
            MarksResultStudentRow.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}
