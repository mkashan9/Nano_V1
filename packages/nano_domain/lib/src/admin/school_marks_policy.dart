/// SCH-06 school marks / result policy snapshot.
class SchoolMarksPolicy {
  const SchoolMarksPolicy({
    required this.schoolId,
    required this.attendanceMode,
    required this.passingPercent,
    required this.allowBonus,
    required this.reportCardFormat,
    required this.gradeBands,
    required this.periods,
  });

  final String schoolId;
  final String attendanceMode;
  final double passingPercent;
  final bool allowBonus;
  final String reportCardFormat;
  final List<GradeBand> gradeBands;
  final List<ResultPeriod> periods;

  List<ResultPeriod> get openPeriods => [
        for (final p in periods)
          if (p.isOpen) p,
      ];

  factory SchoolMarksPolicy.fromJson(Map<String, dynamic> json) {
    final bandsRaw = json['grade_bands'];
    final periodsRaw = json['periods'];
    return SchoolMarksPolicy(
      schoolId: json['school_id'] as String? ?? '',
      attendanceMode: json['attendance_mode'] as String? ?? 'daily',
      passingPercent: (json['passing_percent'] as num?)?.toDouble() ?? 40,
      allowBonus: json['allow_bonus'] as bool? ?? false,
      reportCardFormat: json['report_card_format'] as String? ?? 'both',
      gradeBands: [
        if (bandsRaw is List)
          for (final row in bandsRaw.whereType<Map>())
            GradeBand.fromJson(Map<String, dynamic>.from(row)),
      ],
      periods: [
        if (periodsRaw is List)
          for (final row in periodsRaw.whereType<Map>())
            ResultPeriod.fromJson(Map<String, dynamic>.from(row)),
      ],
    );
  }

  static const defaultGradeBands = [
    GradeBand(min: 90, label: 'A+'),
    GradeBand(min: 80, label: 'A'),
    GradeBand(min: 70, label: 'B'),
    GradeBand(min: 60, label: 'C'),
    GradeBand(min: 50, label: 'D'),
    GradeBand(min: 0, label: 'F'),
  ];
}

class GradeBand {
  const GradeBand({required this.min, required this.label});

  final double min;
  final String label;

  Map<String, dynamic> toJson() => {'min': min, 'label': label};

  factory GradeBand.fromJson(Map<String, dynamic> json) {
    return GradeBand(
      min: (json['min'] as num?)?.toDouble() ?? 0,
      label: json['label'] as String? ?? '',
    );
  }
}

class ResultPeriod {
  const ResultPeriod({
    required this.id,
    required this.name,
    required this.status,
    this.startsOn,
    this.endsOn,
    this.closedAt,
    this.closedReason,
  });

  final String id;
  final String name;
  final String status;
  final String? startsOn;
  final String? endsOn;
  final String? closedAt;
  final String? closedReason;

  bool get isOpen => status == 'open';

  factory ResultPeriod.fromJson(Map<String, dynamic> json) {
    return ResultPeriod(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? '',
      status: json['status'] as String? ?? 'open',
      startsOn: json['starts_on']?.toString(),
      endsOn: json['ends_on']?.toString(),
      closedAt: json['closed_at']?.toString(),
      closedReason: json['closed_reason'] as String?,
    );
  }
}
