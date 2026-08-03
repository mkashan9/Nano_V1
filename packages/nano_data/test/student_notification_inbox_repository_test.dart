import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeStudentNotificationInboxRepository', () {
    test('seeds unread and read items', () async {
      final repo = FakeStudentNotificationInboxRepository();
      final all = await repo.listInbox();
      expect(all, isNotEmpty);
      expect(await repo.unreadCount(), greaterThan(0));
      expect(all.first.createdAt.isAfter(all.last.createdAt), isTrue);
    });

    test('filters unread and marks read', () async {
      final repo = FakeStudentNotificationInboxRepository();
      final unreadBefore = await repo.listInbox(filter: InboxFilter.unread);
      expect(unreadBefore, isNotEmpty);

      final marked = await repo.markRead(unreadBefore.first.id);
      expect(marked.isUnread, isFalse);

      final unreadAfter = await repo.listInbox(filter: InboxFilter.unread);
      expect(unreadAfter.length, unreadBefore.length - 1);
    });

    test('markUnread clears readAt', () async {
      final repo = FakeStudentNotificationInboxRepository();
      final read = (await repo.listInbox())
          .firstWhere((item) => !item.isUnread);
      final unread = await repo.markUnread(read.id);
      expect(unread.isUnread, isTrue);
    });

    test('alwaysFail surfaces errors', () async {
      final repo = FakeStudentNotificationInboxRepository()..alwaysFail = true;
      expect(repo.listInbox(), throwsStateError);
      expect(repo.unreadCount(), throwsStateError);
    });
  });
}
