import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses classroom list with schedule, expiry, and ack counts', () {
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
          'scheduled_publish_at': '2026-08-10T00:00:00Z',
          'expires_at': '2026-08-20T00:00:00Z',
          'requires_acknowledgement': true,
          'is_expired': false,
          'ack_count': 0,
          'roster_count': 2,
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
    expect(list.items.first.isScheduled, isTrue);
    expect(list.items.first.displayStatus, 'scheduled');
    expect(list.items.first.attachments, hasLength(1));
    expect(list.items.first.rosterCount, 2);
  });
}
