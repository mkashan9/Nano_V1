/// STU-06 student in-app notification inbox models.

enum InboxFilter {
  all,
  unread;
}

class InboxItem {
  const InboxItem({
    required this.id,
    required this.category,
    required this.title,
    required this.body,
    required this.createdAt,
    this.readAt,
    this.deepLinkPath = '/',
  });

  final String id;
  final String category;
  final String title;
  final String body;
  final DateTime createdAt;
  final DateTime? readAt;
  final String deepLinkPath;

  bool get isUnread => readAt == null;

  InboxItem copyWith({DateTime? readAt, bool clearReadAt = false}) {
    return InboxItem(
      id: id,
      category: category,
      title: title,
      body: body,
      createdAt: createdAt,
      readAt: clearReadAt ? null : (readAt ?? this.readAt),
      deepLinkPath: deepLinkPath,
    );
  }

  factory InboxItem.fromJson(Map<String, dynamic> json) {
    return InboxItem(
      id: json['id'] as String? ?? '',
      category: json['category'] as String? ?? 'system',
      title: json['title'] as String? ?? '',
      body: json['body'] as String? ?? '',
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ??
          DateTime.fromMillisecondsSinceEpoch(0, isUtc: true),
      readAt: json['read_at'] == null
          ? null
          : DateTime.tryParse('${json['read_at']}'),
      deepLinkPath: json['deep_link_path'] as String? ?? '/',
    );
  }
}

abstract final class InboxMath {
  static int unreadCount(Iterable<InboxItem> items) =>
      items.where((item) => item.isUnread).length;

  static List<InboxItem> applyFilter(
    Iterable<InboxItem> items,
    InboxFilter filter,
  ) {
    final list = [...items]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (filter == InboxFilter.unread) {
      return [for (final item in list) if (item.isUnread) item];
    }
    return list;
  }
}
