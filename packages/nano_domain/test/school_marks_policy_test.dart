import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses marks policy and periods', () {
    final policy = SchoolMarksPolicy.fromJson({
      'school_id': TenancyFixtures.alphaSchoolId,
      'attendance_mode': 'session',
      'passing_percent': 45,
      'allow_bonus': true,
      'report_card_format': 'grade',
      'grade_bands': [
        {'min': 90, 'label': 'A+'},
        {'min': 0, 'label': 'F'},
      ],
      'periods': [
        {
          'id': 'p1',
          'name': 'Term 1',
          'status': 'open',
          'starts_on': '2026-08-01',
        },
      ],
    });
    expect(policy.attendanceMode, 'session');
    expect(policy.passingPercent, 45);
    expect(policy.openPeriods, hasLength(1));
    expect(policy.gradeBands.first.label, 'A+');
  });
}
