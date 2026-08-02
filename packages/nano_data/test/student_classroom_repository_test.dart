import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';

void main() {
  test('loads feed and acknowledges pending items', () async {
    final repo = FakeStudentClassroomRepository();
    final feed = await repo.loadFeed();
    expect(feed.pendingAckCount, 1);

    final after = await repo.acknowledge(feed.items.first.id);
    expect(after.pendingAckCount, 0);
    expect(after.items.first.acknowledged, isTrue);
  });

  test('cannot acknowledge expired items', () async {
    final repo = FakeStudentClassroomRepository();
    final feed = await repo.loadFeed();
    final expired = feed.items.firstWhere((i) => i.isExpired);
    expect(() => repo.acknowledge(expired.id), throwsStateError);
  });
}
