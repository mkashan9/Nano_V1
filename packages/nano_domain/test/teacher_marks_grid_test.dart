import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses marks grid and cycles status', () {
    final grid = TeacherMarksGrid.fromJson({
      'assessment_id': 'asm-1',
      'assignment_id': 'asg-1',
      'school_id': 'school-1',
      'assessment_name': 'Chapter 1',
      'category': 'Quiz',
      'assessment_date': '2026-08-03',
      'total_marks': 20,
      'assessment_status': 'draft',
      'allow_bonus': false,
      'class_label': '5-A',
      'subject_code': 'MATH',
      'roster': [
        {'id': 'stu-1', 'display_name': 'Ali'},
      ],
      'entries': [
        {
          'student_user_id': 'stu-1',
          'status': 'scored',
          'obtained_marks': 18,
          'remarks': 'Good',
        },
      ],
    });

    expect(grid.isDraft, isTrue);
    expect(grid.entryByStudent['stu-1']!.obtainedMarks, 18);
    expect(MarksEntryStatus.scored.next, MarksEntryStatus.absent);
    expect(MarksEntryStatus.notSubmitted.wire, 'not_submitted');
  });
}
