import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  final now = DateTime.utc(2026, 8, 3);

  WeeklyGuidancePackage draft({
    String title = 'Weekly tip',
    String body = 'Celebrate short daily learning.',
    String? pdf,
    List<String> tips = const ['Read together'],
  }) {
    return WeeklyGuidancePackage(
      id: 'wg-1',
      weekKey: '2026-W08',
      titleEn: title,
      bodyEn: body,
      status: WeeklyGuidancePackageStatus.draft,
      updatedAt: now,
      activityTips: tips,
      pdfFileName: pdf,
    );
  }

  test('publish policy requires title, body, week, and PDF', () {
    expect(WeeklyGuidancePublishPolicy.canPublish(draft(pdf: 'a.pdf')), isTrue);
    expect(
      WeeklyGuidancePublishPolicy.validateForPublish(draft(title: ' ', pdf: 'a.pdf')),
      'Title is required',
    );
    expect(
      WeeklyGuidancePublishPolicy.validateForPublish(draft(body: '', pdf: 'a.pdf')),
      'Body is required',
    );
    expect(
      WeeklyGuidancePublishPolicy.validateForPublish(draft()),
      'PDF filename is required before publish',
    );
  });

  test('published package maps to PAR-01 parent card', () {
    final published = draft(pdf: 'week.pdf').copyWith(
      status: WeeklyGuidancePackageStatus.published,
      publishedAt: now,
    );
    final card = published.toParentGuidanceCard();
    expect(card.id, 'wg-1');
    expect(card.weekKey, '2026-W08');
    expect(card.title, 'Weekly tip');
    expect(card.activityTips, ['Read together']);
    expect(card.publishedAt, now);
  });

  test('fromJson round-trips status and tips', () {
    final package = WeeklyGuidancePackage.fromJson({
      'id': 'wg-2',
      'week_key': '2026-W09',
      'title_en': 'Tip',
      'body_en': 'Body',
      'status': 'published',
      'updated_at': '2026-08-03T00:00:00.000Z',
      'activity_tips': ['A', 'B'],
      'pdf_file_name': 'x.pdf',
      'published_at': '2026-08-03T00:00:00.000Z',
    });
    expect(package.isPublished, isTrue);
    expect(package.hasPdf, isTrue);
    expect(package.activityTips, ['A', 'B']);
  });
}
