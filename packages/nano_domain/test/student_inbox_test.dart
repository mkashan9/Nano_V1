import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  final items = [
    InboxItem(
      id: 'a',
      category: 'learning',
      title: 'A',
      body: 'first',
      createdAt: DateTime.utc(2026, 8, 2, 10),
    ),
    InboxItem(
      id: 'b',
      category: 'school',
      title: 'B',
      body: 'second',
      createdAt: DateTime.utc(2026, 8, 2, 9),
      readAt: DateTime.utc(2026, 8, 2, 9, 30),
    ),
    InboxItem(
      id: 'c',
      category: 'account',
      title: 'C',
      body: 'third',
      createdAt: DateTime.utc(2026, 8, 1),
    ),
  ];

  test('unreadCount ignores read items', () {
    expect(InboxMath.unreadCount(items), 2);
  });

  test('applyFilter sorts newest first and can keep unread only', () {
    final all = InboxMath.applyFilter(items, InboxFilter.all);
    expect(all.map((item) => item.id), ['a', 'b', 'c']);

    final unread = InboxMath.applyFilter(items, InboxFilter.unread);
    expect(unread.map((item) => item.id), ['a', 'c']);
  });

  test('fromJson and copyWith round-trip read state', () {
    final parsed = InboxItem.fromJson({
      'id': 'n1',
      'category': 'learning',
      'title': 'Hi',
      'body': 'Body',
      'created_at': '2026-08-02T09:00:00Z',
      'deep_link_path': '/learning',
    });
    expect(parsed.isUnread, isTrue);
    expect(parsed.deepLinkPath, '/learning');

    final read = parsed.copyWith(readAt: DateTime.utc(2026, 8, 2, 10));
    expect(read.isUnread, isFalse);
    expect(read.copyWith(clearReadAt: true).isUnread, isTrue);
  });
}
