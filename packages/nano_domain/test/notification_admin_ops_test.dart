import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('template parses and publish policy', () {
    final template = AdminNotificationTemplate.fromJson({
      'id': 't1',
      'slug': 'marks_published',
      'category': 'school',
      'title_en': 'Marks published',
      'status': 'published',
      'enabled': true,
      'mandatory': false,
      'channel_policy': 'both',
      'deep_link_template': '/flex/marks',
    });
    expect(template.isLive, isTrue);
    expect(NotificationTemplatePublishPolicy.ready(template), isTrue);
  });

  test('empty title is not publish-ready', () {
    const template = AdminNotificationTemplate(
      id: 't1',
      slug: 'x',
      category: 'system',
      titleEn: '  ',
      status: CatalogPublishStatus.draft,
      enabled: true,
    );
    expect(NotificationTemplatePublishPolicy.ready(template), isFalse);
  });
}
