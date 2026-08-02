import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses classroom feed and pending ack count', () {
    final feed = StudentClassroomFeed.fromJson({
      'items': [
        {
          'id': 'c1',
          'title': 'Homework',
          'body': 'Chapter 2',
          'status': 'published',
          'requires_acknowledgement': true,
          'acknowledged': false,
          'is_expired': false,
          'attachments': [],
        },
        {
          'id': 'c2',
          'title': 'Old',
          'body': '',
          'status': 'published',
          'requires_acknowledgement': true,
          'acknowledged': false,
          'is_expired': true,
          'attachments': [],
        },
      ],
    });
    expect(feed.items, hasLength(2));
    expect(feed.pendingAckCount, 1);
    expect(feed.items.first.canAcknowledge, isTrue);
    expect(feed.items.last.canAcknowledge, isFalse);
  });
}
