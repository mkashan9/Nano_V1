import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses marks result summary payload', () {
    final summary = MarksResultSummary.fromJson({
      'assessment_id': 'a1',
      'assignment_id': 'asg-1',
      'school_id': TenancyFixtures.alphaSchoolId,
      'class_label': '5-A',
      'subject_code': 'MATH',
      'assessment_name': 'Quiz',
      'assessment_status': 'published',
      'total_marks': 20,
      'passing_percent': 40,
      'report_card_format': 'both',
      'roster_count': 2,
      'scored_count': 1,
      'absent_count': 1,
      'exempt_count': 0,
      'not_submitted_count': 0,
      'average_percent': 75,
      'median_percent': 75,
      'highest_percent': 75,
      'lowest_percent': 75,
      'pass_count': 1,
      'fail_count': 0,
      'pass_rate_percent': 100,
      'grade_distribution': [
        {'label': 'A', 'count': 0},
        {'label': 'B', 'count': 1},
      ],
      'students': [
        {
          'student_user_id': TenancyFixtures.aliAlphaId,
          'display_name': 'Ali Khan',
          'status': 'scored',
          'obtained_marks': 15,
          'percent': 75,
          'passed': true,
          'grade_label': 'B',
        },
      ],
    });

    expect(summary.scopeLabel, '5-A · MATH');
    expect(summary.averagePercent, 75);
    expect(summary.passRatePercent, 100);
    expect(summary.students, hasLength(1));
    expect(summary.gradeDistribution.first.label, 'A');
  });
}
