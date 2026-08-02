import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses marks correction result payload', () {
    final result = MarksCorrectionResult.fromJson({
      'corrected': true,
      'correction_id': 'c1',
      'grid': {
        'assessment_id': 'a1',
        'assignment_id': 'asg-1',
        'school_id': TenancyFixtures.alphaSchoolId,
        'assessment_name': 'Quiz',
        'category': 'Quiz',
        'assessment_date': '2026-08-03',
        'total_marks': 20,
        'assessment_status': 'corrected',
        'allow_bonus': false,
        'class_label': '5-A',
        'subject_code': 'MATH',
        'roster': [
          {'id': TenancyFixtures.aliAlphaId, 'display_name': 'Ali Khan'},
        ],
        'entries': [
          {
            'student_user_id': TenancyFixtures.aliAlphaId,
            'status': 'absent',
            'obtained_marks': null,
            'remarks': '',
          },
        ],
      },
      'history': {
        'assessment_id': 'a1',
        'corrections': [
          {
            'id': 'c1',
            'assessment_id': 'a1',
            'student_user_id': TenancyFixtures.aliAlphaId,
            'display_name': 'Ali Khan',
            'previous_status': 'scored',
            'new_status': 'absent',
            'previous_obtained_marks': 15,
            'new_obtained_marks': null,
            'previous_remarks': '',
            'new_remarks': '',
            'reason': 'Sick',
            'corrected_by': 't1',
            'corrected_by_name': 'Teacher',
            'corrected_at': '2026-08-02T12:00:00Z',
            'revision_before': 1,
            'revision_after': 2,
          },
        ],
      },
    });

    expect(result.corrected, isTrue);
    expect(result.grid.isCorrectable, isTrue);
    expect(result.history.corrections, hasLength(1));
    expect(result.history.corrections.first.reason, 'Sick');
    expect(
      result.history.corrections.first.previousStatus,
      MarksEntryStatus.scored,
    );
  });
}
