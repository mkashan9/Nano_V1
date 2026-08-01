import 'learning_content_ops.dart';

/// ADM-07 curator models for platform notification templates.
class AdminNotificationTemplate {
  const AdminNotificationTemplate({
    required this.id,
    required this.slug,
    required this.category,
    required this.titleEn,
    required this.status,
    required this.enabled,
    this.titleUr = '',
    this.bodyEn = '',
    this.bodyUr = '',
    this.deepLinkTemplate = '/',
    this.channelPolicy = 'in_app',
    this.mandatory = false,
    this.sortOrder = 0,
    this.publishedAt,
  });

  final String id;
  final String slug;
  final String category;
  final String titleEn;
  final String titleUr;
  final String bodyEn;
  final String bodyUr;
  final String deepLinkTemplate;
  final String channelPolicy;
  final CatalogPublishStatus status;
  final bool enabled;
  final bool mandatory;
  final int sortOrder;
  final DateTime? publishedAt;

  bool get isDraft => status == CatalogPublishStatus.draft;
  bool get isPublished => status == CatalogPublishStatus.published;
  bool get isLive => isPublished && enabled;

  factory AdminNotificationTemplate.fromJson(Map<String, dynamic> json) {
    return AdminNotificationTemplate(
      id: json['id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: json['category'] as String? ?? 'system',
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      bodyEn: json['body_en'] as String? ?? '',
      bodyUr: json['body_ur'] as String? ?? '',
      deepLinkTemplate: json['deep_link_template'] as String? ?? '/',
      channelPolicy: json['channel_policy'] as String? ?? 'in_app',
      status: CatalogPublishStatus.fromWire(json['status'] as String?),
      enabled: json['enabled'] as bool? ?? true,
      mandatory: json['mandatory'] as bool? ?? false,
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 0,
      publishedAt: json['published_at'] == null
          ? null
          : DateTime.tryParse('${json['published_at']}'),
    );
  }
}

abstract final class NotificationTemplatePublishPolicy {
  static bool ready(AdminNotificationTemplate template) =>
      template.titleEn.trim().isNotEmpty;
}
