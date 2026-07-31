import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  final mathRows = [
    {
      'subject_id': 's-math',
      'subject_slug': 'math',
      'subject_order': 1,
      'subject_version_id': 'sv-math-1',
      'subject_title': 'Math',
      'subject_title_ur': 'حساب',
      'subject_summary': 'Numbers',
      'world_color_hex': '#2F7BFF',
      'topic_id': 't-counting',
      'topic_slug': 'counting',
      'topic_order': 1,
      'topic_version_id': 'tv-counting-1',
      'topic_title': 'Counting to 20',
      'topic_title_ur': '20 تک گنتی',
      'objectives': ['Count objects to 20'],
      'estimated_minutes': 12,
      'resources': <String>[],
      'progress_status': 'not_started',
      'progress': 0,
      'resume_seconds': 0,
      'blocking_titles': <String>[],
      'is_locked': false,
    },
    {
      'subject_id': 's-math',
      'subject_slug': 'math',
      'subject_order': 1,
      'subject_version_id': 'sv-math-1',
      'subject_title': 'Math',
      'subject_title_ur': 'حساب',
      'subject_summary': 'Numbers',
      'world_color_hex': '#2F7BFF',
      'topic_id': 't-addition',
      'topic_slug': 'addition',
      'topic_order': 2,
      'topic_version_id': 'tv-addition-1',
      'topic_title': 'Adding small numbers',
      'topic_title_ur': 'چھوٹے اعداد جمع',
      'objectives': ['Add within 20'],
      'estimated_minutes': 15,
      'resources': <String>[],
      'progress_status': 'not_started',
      'progress': 0,
      'resume_seconds': 0,
      'blocking_titles': ['Counting to 20'],
      'is_locked': true,
    },
  ];

  test('groups rows and reports lock state from the server', () {
    final catalog = LearningCatalog.fromRows(
      mathRows,
      updatedAt: DateTime.utc(2026, 7, 31),
    );
    expect(catalog.subjects, hasLength(1));
    final math = catalog.subjects.single;
    expect(math.subjectVersionId, 'sv-math-1');
    expect(math.topics, hasLength(2));
    expect(math.topics.first.isLocked, isFalse);
    expect(math.topics.last.isLocked, isTrue);
    expect(math.topics.last.blockingTitles, ['Counting to 20']);
    expect(math.nextTopic?.topicVersionId, 'tv-counting-1');
  });

  test('junior and senior share the same topic version IDs', () {
    final junior = LearningCatalog.fromRows(
      mathRows,
      updatedAt: DateTime.utc(2026, 7, 31),
    );
    final senior = LearningCatalog.fromRows(
      mathRows,
      updatedAt: DateTime.utc(2026, 7, 31),
    );
    expect(junior.topicVersionIds, senior.topicVersionIds);
  });

  test('search matches subject and topic titles for seniors', () {
    final catalog = LearningCatalog.fromRows(
      mathRows,
      updatedAt: DateTime.utc(2026, 7, 31),
    );
    expect(catalog.search('add'), hasLength(1));
    expect(catalog.search('xyz'), isEmpty);
    expect(catalog.search('حساب'), hasLength(1));
  });

  test('completing the first topic unlocks the next recommendation', () {
    final unlocked = [
      {...mathRows.first, 'progress_status': 'completed', 'progress': 1},
      {
        ...mathRows.last,
        'blocking_titles': <String>[],
        'is_locked': false,
      },
    ];
    final catalog = LearningCatalog.fromRows(
      unlocked,
      updatedAt: DateTime.utc(2026, 7, 31),
    );
    final next = catalog.nextRecommendation!;
    expect(next.topicVersionId, 'tv-addition-1');
    expect(next.isLocked, isFalse);
  });

  test('toHomeSubject reuses the shared home record', () {
    final subject = CatalogSubject.fromRows(mathRows);
    final home = subject.toHomeSubject();
    expect(home.id, 's-math');
    expect(home.title, 'Math');
    expect(home.worldColorValue, 0xFF2F7BFF);
    expect(home.estimatedMinutes, 27);
  });

  test('parseWorldColor falls back safely', () {
    expect(CatalogSubject.parseWorldColor('#FF8A3D'), 0xFFFF8A3D);
    expect(CatalogSubject.parseWorldColor('bad'), CatalogSubject.fallbackWorldColor);
  });
}
