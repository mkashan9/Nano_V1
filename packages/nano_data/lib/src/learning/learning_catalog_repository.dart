import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Reads the learning catalog the signed-in learner is allowed to see.
///
/// The client never filters drafts or eligibility: both are enforced by RLS on
/// the `learning_catalog` read model, and prerequisite lock state is computed
/// server-side.
abstract class LearningCatalogRepository {
  Future<LearningCatalog> loadCatalog();

  /// Same rows as [loadCatalog], narrowed to one subject.
  Future<CatalogSubject?> loadSubject(String subjectId);
}

/// Deterministic catalog fixtures mirroring the seeded development content.
class FakeLearningCatalogRepository implements LearningCatalogRepository {
  FakeLearningCatalogRepository({
    this.alwaysFail = false,
    this.failOnce = false,
    this.servesCache = false,
    this.seniorEligible = false,
    this.countingCompleted = false,
    this.additionStarted = false,
    this.empty = false,
    this.delay = Duration.zero,
    this.cacheAge = const Duration(hours: 4),
  });

  final bool alwaysFail;
  bool failOnce;
  final bool servesCache;

  /// Stands in for the server eligibility rule that hides senior-only subjects.
  final bool seniorEligible;
  final bool countingCompleted;
  final bool additionStarted;
  final bool empty;
  final Duration delay;
  final Duration cacheAge;

  var loadCount = 0;

  @override
  Future<LearningCatalog> loadCatalog() async {
    loadCount++;
    if (delay > Duration.zero) {
      await Future<void>.delayed(delay);
    }
    if (alwaysFail) throw StateError('Catalog unavailable');
    if (failOnce) {
      failOnce = false;
      throw StateError('Catalog unavailable');
    }
    final now = DateTime.now().toUtc();
    return LearningCatalog(
      subjects: empty ? const [] : _subjects(),
      updatedAt: servesCache ? now.subtract(cacheAge) : now,
      fromCache: servesCache,
    );
  }

  @override
  Future<CatalogSubject?> loadSubject(String subjectId) async {
    final catalog = await loadCatalog();
    return catalog.subjectById(subjectId);
  }

  List<CatalogSubject> _subjects() {
    final counting = CatalogTopic(
      topicId: 'topic-counting',
      topicVersionId: 'tv-counting-1',
      slug: 'counting',
      title: 'Counting to 20',
      titleUr: '20 تک گنتی',
      order: 1,
      estimatedMinutes: 12,
      objectives: const ['Count objects to 20', 'Recognise number order'],
      durationSeconds: 120,
      videoProvider: 'fixture',
      videoRef: 'counting-to-20',
      captions: const CaptionTrack([
        CaptionCue(
          atSeconds: 0,
          text: 'Let us count to twenty.',
          textUr: 'آئیے بیس تک گنتی کریں۔',
        ),
        CaptionCue(
          atSeconds: 30,
          text: 'Ten comes after nine.',
          textUr: 'نو کے بعد دس آتا ہے۔',
        ),
      ]),
      status: countingCompleted
          ? TopicProgressStatus.completed
          : TopicProgressStatus.notStarted,
      progress: countingCompleted ? 1 : 0,
      watchedSeconds: countingCompleted ? 120 : 0,
    );
    final addition = CatalogTopic(
      topicId: 'topic-addition',
      topicVersionId: 'tv-addition-1',
      slug: 'addition',
      title: 'Adding small numbers',
      titleUr: 'چھوٹے اعداد جمع',
      order: 2,
      estimatedMinutes: 15,
      objectives: const ['Add within 20', 'Use a number line'],
      durationSeconds: 150,
      videoProvider: 'fixture',
      videoRef: 'adding-small-numbers',
      status: additionStarted
          ? TopicProgressStatus.inProgress
          : TopicProgressStatus.notStarted,
      progress: additionStarted ? 0.4 : 0,
      resumeSeconds: additionStarted ? 90 : 0,
      watchedSeconds: additionStarted ? 60 : 0,
      // Locked until counting is finished, exactly as the server reports it.
      blockingTitles: countingCompleted ? const [] : const ['Counting to 20'],
    );
    return [
      CatalogSubject(
        subjectId: 'subject-math',
        subjectVersionId: 'sv-math-1',
        slug: 'math',
        title: 'Math',
        titleUr: 'حساب',
        summary: 'Numbers, counting and addition.',
        worldColorValue: 0xFF2F7BFF,
        order: 1,
        topics: [counting, addition],
      ),
      if (seniorEligible)
        CatalogSubject(
          subjectId: 'subject-science',
          subjectVersionId: 'sv-science-1',
          slug: 'science',
          title: 'Science',
          titleUr: 'سائنس',
          summary: 'Living things and matter.',
          worldColorValue: 0xFFFF8A3D,
          order: 2,
          topics: const [
            CatalogTopic(
              topicId: 'topic-living-things',
              topicVersionId: 'tv-living-things-1',
              slug: 'living-things',
              title: 'Living things',
              titleUr: 'جاندار',
              order: 1,
              estimatedMinutes: 18,
              objectives: ['Sort living and non-living'],
              durationSeconds: 180,
              videoProvider: 'fixture',
              videoRef: 'living-things',
              captions: CaptionTrack([
                CaptionCue(
                  atSeconds: 0,
                  text: 'Living things grow.',
                  textUr: 'جاندار بڑھتے ہیں۔',
                ),
              ]),
            ),
            CatalogTopic(
              topicId: 'topic-plants',
              topicVersionId: 'tv-plants-1',
              slug: 'plants-and-animals',
              title: 'Plants and animals',
              titleUr: 'پودے اور جانور',
              order: 2,
              estimatedMinutes: 16,
              objectives: [
                'Compare plants and animals',
                'Name what living things need',
              ],
              durationSeconds: 160,
              videoProvider: 'fixture',
              videoRef: 'plants-and-animals',
              blockingTitles: ['Living things'],
            ),
          ],
        ),
    ];
  }
}

class SupabaseLearningCatalogRepository implements LearningCatalogRepository {
  SupabaseLearningCatalogRepository(this._client);

  static const _columns =
      'subject_id, subject_slug, subject_order, subject_version_id, '
      'subject_title, subject_title_ur, subject_summary, world_color_hex, '
      'topic_id, topic_slug, topic_order, topic_version_id, topic_title, '
      'topic_title_ur, objectives, estimated_minutes, resources, '
      'duration_seconds, completion_threshold, video_provider, video_ref, '
      'captions, progress_status, progress, resume_seconds, watched_seconds, '
      'blocking_titles, is_locked';

  final SupabaseClient _client;

  @override
  Future<LearningCatalog> loadCatalog() async {
    final rows = await _client
        .from('learning_catalog')
        .select(_columns)
        .order('subject_order')
        .order('topic_order');
    return LearningCatalog.fromRows(
      [
        for (final row in rows as List<dynamic>) row as Map<String, dynamic>,
      ],
      updatedAt: DateTime.now().toUtc(),
    );
  }

  @override
  Future<CatalogSubject?> loadSubject(String subjectId) async {
    final rows = await _client
        .from('learning_catalog')
        .select(_columns)
        .eq('subject_id', subjectId)
        .order('topic_order');
    final list = [
      for (final row in rows as List<dynamic>) row as Map<String, dynamic>,
    ];
    if (list.isEmpty) return null;
    return CatalogSubject.fromRows(list);
  }
}
