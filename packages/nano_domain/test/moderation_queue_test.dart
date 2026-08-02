import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('ModerationQueueItem.fromJson maps evidence without user ids', () {
    final item = ModerationQueueItem.fromJson({
      'id': 'r1',
      'category': 'spam',
      'status': 'under_review',
      'peer_label': 'sara',
      'reporter_label': 'ali',
      'username': 'sara',
      'also_blocked': true,
      'evidence': {'peer_label': 'sara', 'context': 'user'},
    });

    expect(item.status, ReportStatus.underReview);
    expect(item.category, ReportCategory.spam);
    expect(item.reporterLabel, 'ali');
    expect(item.evidence['context'], 'user');
    expect(item.toString(), isNot(contains('user_id')));
  });
}
