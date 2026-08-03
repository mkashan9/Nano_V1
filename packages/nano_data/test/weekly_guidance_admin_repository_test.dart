import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('createDraft then attachPdf then publish', () async {
    final repo = FakeWeeklyGuidanceAdminRepository();
    final created = await repo.createDraft(
      weekKey: '2026-W08',
      titleEn: 'Weekly tip',
      bodyEn: 'Celebrate short daily learning.',
    );
    expect(created.status, WeeklyGuidancePackageStatus.draft);

    final withPdf = await repo.attachPdf(
      id: created.id,
      pdfFileName: 'week-guidance.pdf',
    );
    expect(withPdf.hasPdf, isTrue);

    await repo.setActivityTips(
      id: created.id,
      tips: ['Read together', ' ', 'Ask one question'],
    );

    final published = await repo.publish(created.id);
    expect(published.isPublished, isTrue);
    expect(published.activityTips, ['Read together', 'Ask one question']);
    expect(published.publishedAt, isNotNull);
  });

  test('publish without PDF fails', () async {
    final repo = FakeWeeklyGuidanceAdminRepository();
    final created = await repo.createDraft(
      weekKey: '2026-W08',
      titleEn: 'Weekly tip',
      bodyEn: 'Body',
    );
    expect(() => repo.publish(created.id), throwsStateError);
  });

  test('attachPdf rejects non-pdf names', () async {
    final repo = FakeWeeklyGuidanceAdminRepository();
    final created = await repo.createDraft(
      weekKey: '2026-W08',
      titleEn: 'Weekly tip',
      bodyEn: 'Body',
    );
    expect(
      () => repo.attachPdf(id: created.id, pdfFileName: 'notes.txt'),
      throwsArgumentError,
    );
  });
}
