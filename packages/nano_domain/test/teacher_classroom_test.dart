import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses classroom list payload', () {
    final list = TeacherClassroomList.fromJson({
      'assignment_id': 'asg-1',
      'school_id': TenancyFixtures.alphaSchoolId,
      'class_label': '5-A',
      'subject_code': 'MATH',
      'items': [
        {
          'id': 'c1',
          'school_id': TenancyFixtures.alphaSchoolId,
          'teacher_assignment_id': 'asg-1',
          'title': 'Homework reminder',
          'body': 'Bring notebooks',
          'status': 'draft',
        },
      ],
    });
    expect(list.scopeLabel, '5-A · MATH');
    expect(list.items, hasLength(1));
    expect(list.items.first.isDraft, isTrue);
    expect(list.items.first.title, 'Homework reminder');
  });
}
