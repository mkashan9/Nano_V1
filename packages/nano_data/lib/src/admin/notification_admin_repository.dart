import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// ADM-07 platform notification template administration.
abstract class NotificationAdminRepository {
  Future<List<AdminNotificationTemplate>> listTemplates({String query = ''});

  Future<AdminNotificationTemplate> createDraft({
    required String slug,
    required String titleEn,
    String titleUr = '',
    String bodyEn = '',
    String bodyUr = '',
    String category = 'system',
    String deepLinkTemplate = '/',
    String channelPolicy = 'in_app',
    bool mandatory = false,
  });

  Future<AdminNotificationTemplate> publish(String templateId);

  Future<AdminNotificationTemplate> disable({
    required String templateId,
    required String reason,
  });
}

class FakeNotificationAdminRepository implements NotificationAdminRepository {
  FakeNotificationAdminRepository({List<AdminNotificationTemplate>? seed})
      : _templates = List.of(seed ?? _defaultSeed);

  final List<AdminNotificationTemplate> _templates;
  var createCount = 0;

  static final _defaultSeed = <AdminNotificationTemplate>[
    AdminNotificationTemplate(
      id: '70000000-0000-0000-0000-000000000001',
      slug: 'marks_published',
      category: 'school',
      titleEn: 'Marks published',
      titleUr: 'نمبر شائع',
      bodyEn: 'New marks are ready to view.',
      deepLinkTemplate: '/flex/marks',
      channelPolicy: 'both',
      status: CatalogPublishStatus.published,
      enabled: true,
      sortOrder: 10,
      publishedAt: DateTime.utc(2026, 8, 1),
    ),
    AdminNotificationTemplate(
      id: '70000000-0000-0000-0000-000000000002',
      slug: 'achievement_unlocked',
      category: 'gamification',
      titleEn: 'Achievement unlocked',
      bodyEn: 'You earned a new badge.',
      deepLinkTemplate: '/profile',
      status: CatalogPublishStatus.published,
      enabled: true,
      sortOrder: 20,
      publishedAt: DateTime.utc(2026, 8, 1),
    ),
    AdminNotificationTemplate(
      id: '70000000-0000-0000-0000-000000000003',
      slug: 'account_security',
      category: 'account',
      titleEn: 'Security notice',
      bodyEn: 'Something changed on your account.',
      channelPolicy: 'both',
      status: CatalogPublishStatus.published,
      enabled: true,
      mandatory: true,
      sortOrder: 30,
      publishedAt: DateTime.utc(2026, 8, 1),
    ),
    AdminNotificationTemplate(
      id: '70000000-0000-0000-0000-000000000004',
      slug: 'weekly_digest',
      category: 'learning',
      titleEn: 'Weekly digest',
      bodyEn: "A quiet summary of this week's learning.",
      deepLinkTemplate: '/learning',
      status: CatalogPublishStatus.draft,
      enabled: true,
      sortOrder: 40,
    ),
  ];

  int _indexOf(String id) => _templates.indexWhere((t) => t.id == id);

  AdminNotificationTemplate _require(String id) {
    final index = _indexOf(id);
    if (index < 0) throw StateError('Unknown notification template.');
    return _templates[index];
  }

  @override
  Future<List<AdminNotificationTemplate>> listTemplates({
    String query = '',
  }) async {
    final q = query.trim().toLowerCase();
    final filtered = [
      for (final template in _templates)
        if (q.isEmpty ||
            template.titleEn.toLowerCase().contains(q) ||
            template.slug.contains(q))
          template,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return filtered;
  }

  @override
  Future<AdminNotificationTemplate> createDraft({
    required String slug,
    required String titleEn,
    String titleUr = '',
    String bodyEn = '',
    String bodyUr = '',
    String category = 'system',
    String deepLinkTemplate = '/',
    String channelPolicy = 'in_app',
    bool mandatory = false,
  }) async {
    if (slug.trim().isEmpty || titleEn.trim().isEmpty) {
      throw StateError('Template slug and English title are required.');
    }
    createCount++;
    final created = AdminNotificationTemplate(
      id: 'template-$createCount',
      slug: slug.trim().toLowerCase(),
      category: category,
      titleEn: titleEn.trim(),
      titleUr: titleUr,
      bodyEn: bodyEn,
      bodyUr: bodyUr,
      deepLinkTemplate: deepLinkTemplate,
      channelPolicy: channelPolicy,
      status: CatalogPublishStatus.draft,
      enabled: true,
      mandatory: mandatory,
      sortOrder: (_templates.isEmpty ? 0 : _templates.last.sortOrder) + 10,
    );
    _templates.add(created);
    return created;
  }

  @override
  Future<AdminNotificationTemplate> publish(String templateId) async {
    final current = _require(templateId);
    if (!NotificationTemplatePublishPolicy.ready(current)) {
      throw StateError('Publish requires an English title.');
    }
    if (current.isLive) return current;
    if (current.status == CatalogPublishStatus.archived && !current.enabled) {
      throw StateError(
        'Archived templates cannot be republished. Create a new draft.',
      );
    }
    final published = AdminNotificationTemplate(
      id: current.id,
      slug: current.slug,
      category: current.category,
      titleEn: current.titleEn,
      titleUr: current.titleUr,
      bodyEn: current.bodyEn,
      bodyUr: current.bodyUr,
      deepLinkTemplate: current.deepLinkTemplate,
      channelPolicy: current.channelPolicy,
      status: CatalogPublishStatus.published,
      enabled: true,
      mandatory: current.mandatory,
      sortOrder: current.sortOrder,
      publishedAt: current.publishedAt ?? DateTime.now().toUtc(),
    );
    _templates[_indexOf(templateId)] = published;
    return published;
  }

  @override
  Future<AdminNotificationTemplate> disable({
    required String templateId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError(
        'A reason is required to disable a notification template.',
      );
    }
    final current = _require(templateId);
    final disabled = AdminNotificationTemplate(
      id: current.id,
      slug: current.slug,
      category: current.category,
      titleEn: current.titleEn,
      titleUr: current.titleUr,
      bodyEn: current.bodyEn,
      bodyUr: current.bodyUr,
      deepLinkTemplate: current.deepLinkTemplate,
      channelPolicy: current.channelPolicy,
      status: current.isPublished
          ? CatalogPublishStatus.archived
          : current.status,
      enabled: false,
      mandatory: current.mandatory,
      sortOrder: current.sortOrder,
      publishedAt: current.publishedAt,
    );
    _templates[_indexOf(templateId)] = disabled;
    return disabled;
  }
}

class SupabaseNotificationAdminRepository
    implements NotificationAdminRepository {
  SupabaseNotificationAdminRepository(this._client);

  final SupabaseClient _client;

  Future<AdminNotificationTemplate?> _find(String templateId) async {
    final rows = await listTemplates();
    for (final template in rows) {
      if (template.id == templateId) return template;
    }
    return null;
  }

  @override
  Future<List<AdminNotificationTemplate>> listTemplates({
    String query = '',
  }) async {
    final raw = await _client.rpc('list_notification_templates_admin');
    final templates = [
      for (final row in (raw as List).whereType<Map>())
        AdminNotificationTemplate.fromJson(Map<String, dynamic>.from(row)),
    ];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return templates;
    return [
      for (final template in templates)
        if (template.titleEn.toLowerCase().contains(q) ||
            template.slug.contains(q))
          template,
    ];
  }

  @override
  Future<AdminNotificationTemplate> createDraft({
    required String slug,
    required String titleEn,
    String titleUr = '',
    String bodyEn = '',
    String bodyUr = '',
    String category = 'system',
    String deepLinkTemplate = '/',
    String channelPolicy = 'in_app',
    bool mandatory = false,
  }) async {
    final raw = await _client.rpc(
      'create_notification_template_draft',
      params: {
        'p_slug': slug,
        'p_title_en': titleEn,
        'p_title_ur': titleUr,
        'p_body_en': bodyEn,
        'p_body_ur': bodyUr,
        'p_category': category,
        'p_deep_link_template': deepLinkTemplate,
        'p_channel_policy': channelPolicy,
        'p_mandatory': mandatory,
      },
    );
    return AdminNotificationTemplate.fromJson(
      Map<String, dynamic>.from(raw as Map),
    );
  }

  @override
  Future<AdminNotificationTemplate> publish(String templateId) async {
    await _client.rpc(
      'publish_notification_template',
      params: {'p_id': templateId},
    );
    return (await _find(templateId))!;
  }

  @override
  Future<AdminNotificationTemplate> disable({
    required String templateId,
    required String reason,
  }) async {
    await _client.rpc(
      'disable_notification_template',
      params: {
        'p_id': templateId,
        'p_reason': reason,
      },
    );
    return (await _find(templateId))!;
  }
}
