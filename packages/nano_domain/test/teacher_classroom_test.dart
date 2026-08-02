import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses classroom list with attachments', () {
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
          'attachments': [
            {
              'id': 'a1',
              'classroom_item_id': 'c1',
              'kind': 'link',
              'title': 'Worksheet',
              'url': 'https://example.com/ws.pdf',
              'sort_order': 1,
            },
          ],
        },
      ],
    });
    expect(list.scopeLabel, '5-A · MATH');
    expect(list.items.first.attachments, hasLength(1));
    expect(list.items.first.attachments.first.kind, ClassroomAttachmentKind.link);
    expect(
      list.items.first.attachments.first.url,
      'https://example.com/ws.pdf',
    );
  });
}
