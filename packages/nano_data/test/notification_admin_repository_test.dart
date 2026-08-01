import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('publish draft and disable require reason', () async {
    final repo = FakeNotificationAdminRepository();
    final draft = (await repo.listTemplates())
        .firstWhere((t) => t.status == CatalogPublishStatus.draft);
    final published = await repo.publish(draft.id);
    expect(published.isLive, isTrue);

    expect(
      () => repo.disable(templateId: published.id, reason: ' '),
      throwsStateError,
    );
    final disabled = await repo.disable(
      templateId: published.id,
      reason: 'Copy obsolete',
    );
    expect(disabled.enabled, isFalse);
    expect(disabled.status, CatalogPublishStatus.archived);
  });

  test('create draft adds a template', () async {
    final repo = FakeNotificationAdminRepository();
    final created = await repo.createDraft(
      slug: 'welcome_back',
      titleEn: 'Welcome back',
      bodyEn: 'Glad you returned.',
    );
    expect(created.isDraft, isTrue);
    expect(await repo.listTemplates(), hasLength(5));
  });
}
