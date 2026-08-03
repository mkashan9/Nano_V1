import 'package:nano_domain/nano_domain.dart';

/// STU-06 student in-app notification inbox.
abstract class StudentNotificationInboxRepository {
  Future<List<InboxItem>> listInbox({InboxFilter filter = InboxFilter.all});

  Future<int> unreadCount();

  Future<InboxItem> markRead(String id);

  Future<InboxItem> markUnread(String id);
}

class FakeStudentNotificationInboxRepository
    implements StudentNotificationInboxRepository {
  FakeStudentNotificationInboxRepository({List<InboxItem>? seed})
      : _items = List.of(
          seed ??
              [
                InboxItem(
                  id: 'n1',
                  category: 'learning',
                  title: 'New topic unlocked',
                  body: 'Science — Forces is ready when you are.',
                  createdAt: DateTime.utc(2026, 8, 2, 9),
                  deepLinkPath: '/learning',
                ),
                InboxItem(
                  id: 'n2',
                  category: 'gamification',
                  title: 'Streak reminder',
                  body: 'Keep your 3-day streak going today.',
                  createdAt: DateTime.utc(2026, 8, 2, 8),
                  deepLinkPath: '/',
                ),
                InboxItem(
                  id: 'n3',
                  category: 'school',
                  title: 'Assembly note',
                  body: 'Morning assembly starts at 8:15.',
                  createdAt: DateTime.utc(2026, 8, 1, 15),
                  readAt: DateTime.utc(2026, 8, 1, 16),
                  deepLinkPath: '/',
                ),
                InboxItem(
                  id: 'n4',
                  category: 'account',
                  title: 'Privacy tip',
                  body: 'Review who can find you in Profile settings.',
                  createdAt: DateTime.utc(2026, 8, 1, 12),
                  deepLinkPath: '/me',
                ),
              ],
        );

  final List<InboxItem> _items;
  var alwaysFail = false;

  @override
  Future<List<InboxItem>> listInbox({
    InboxFilter filter = InboxFilter.all,
  }) async {
    if (alwaysFail) throw StateError('Inbox unavailable');
    return InboxMath.applyFilter(_items, filter);
  }

  @override
  Future<int> unreadCount() async {
    if (alwaysFail) throw StateError('Inbox unavailable');
    return InboxMath.unreadCount(_items);
  }

  @override
  Future<InboxItem> markRead(String id) async {
    if (alwaysFail) throw StateError('Mark read failed');
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Notification not found');
    final updated = _items[index].copyWith(readAt: DateTime.now().toUtc());
    _items[index] = updated;
    return updated;
  }

  @override
  Future<InboxItem> markUnread(String id) async {
    if (alwaysFail) throw StateError('Mark unread failed');
    final index = _items.indexWhere((item) => item.id == id);
    if (index < 0) throw StateError('Notification not found');
    final updated = _items[index].copyWith(clearReadAt: true);
    _items[index] = updated;
    return updated;
  }
}
