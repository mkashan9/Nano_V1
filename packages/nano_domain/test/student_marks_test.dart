import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses student marks summary with correction badge', () {
    final summary = StudentMarksSummary.fromJson({
      'from': '2026-08-01',
      'to': '2026-08-31',
      'scored_count': 1,
      'absent_count': 0,
      'exempt_count': 0,
      'not_submitted_count': 0,
      'results': [
        {
          'assessment_id': 'a1',
          'entry_id': 'e1',
          'name': 'Unit test',
          'category': 'quiz',
          'assessment_date': '2026-08-05',
          'assessment_status': 'corrected',
          'status': 'scored',
          'total_marks': 20,
          'obtained_marks': 18,
          'subject_code': 'MATH',
          'correction_count': 1,
        },
      ],
    });
    expect(summary.recordedCount, 1);
    expect(summary.results.first.wasCorrected, isTrue);
    expect(summary.results.first.obtainedMarks, 18);
  });
}
