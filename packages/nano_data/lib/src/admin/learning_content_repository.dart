import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// ADM-04 platform Learning Stack catalog authoring.
abstract class LearningContentRepository {
  Future<List<AuthoringSubject>> listSubjects({String query = ''});

  Future<AuthoringSubject> createSubjectDraft({
    required String slug,
    required String title,
    String summary = '',
    String? titleUr,
    String worldColorHex = '#2F7BFF',
    String track = 'both',
  });

  Future<AuthoringSubject> publishSubject(String subjectVersionId);

  Future<AuthoringSubject> archiveSubject(String subjectVersionId);

  Future<AuthoringTopic> createTopicDraft({
    required String subjectId,
    required String slug,
    required String title,
    String? titleUr,
    List<String> objectives = const [],
    int estimatedMinutes = 10,
    int durationSeconds = 300,
    String videoProvider = 'fixture',
    String videoRef = 'draft://pending',
    String? requiresTopicId,
  });

  Future<AuthoringTopic> publishTopic(String topicVersionId);

  Future<AuthoringTopic> archiveTopic(String topicVersionId);
}

class FakeLearningContentRepository implements LearningContentRepository {
  FakeLearningContentRepository({List<AuthoringSubject>? seed})
      : _subjects = List.of(seed ?? _defaultSeed);

  final List<AuthoringSubject> _subjects;
  var createSubjectCount = 0;
  var createTopicCount = 0;

  static final _defaultSeed = <AuthoringSubject>[
    AuthoringSubject(
      subjectId: '10000000-0000-0000-0000-000000000001',
      slug: 'math',
      subjectVersionId: '20000000-0000-0000-0000-000000000001',
      title: 'Math',
      titleUr: 'حساب',
      summary: 'Numbers, counting and addition.',
      status: CatalogPublishStatus.published,
      order: 1,
      topics: const [
        AuthoringTopic(
          topicId: '30000000-0000-0000-0000-000000000001',
          slug: 'counting',
          topicVersionId: '40000000-0000-0000-0000-000000000001',
          title: 'Counting to 20',
          titleUr: '20 تک گنتی',
          status: CatalogPublishStatus.published,
          order: 1,
          estimatedMinutes: 12,
          durationSeconds: 120,
          videoProvider: 'fixture',
          videoRef: 'fixture://counting',
          objectives: ['Count objects to 20'],
        ),
        AuthoringTopic(
          topicId: '30000000-0000-0000-0000-000000000002',
          slug: 'addition',
          topicVersionId: '40000000-0000-0000-0000-000000000002',
          title: 'Adding small numbers',
          status: CatalogPublishStatus.published,
          order: 2,
          estimatedMinutes: 15,
          durationSeconds: 150,
          videoProvider: 'fixture',
          videoRef: 'fixture://addition',
        ),
      ],
    ),
    AuthoringSubject(
      subjectId: '10000000-0000-0000-0000-000000000003',
      slug: 'coding',
      subjectVersionId: '20000000-0000-0000-0000-000000000003',
      title: 'Coding',
      summary: 'Not published yet.',
      worldColorHex: '#2FBF71',
      status: CatalogPublishStatus.draft,
      order: 3,
      topics: const [
        AuthoringTopic(
          topicId: '30000000-0000-0000-0000-000000000004',
          slug: 'first-loop',
          topicVersionId: '40000000-0000-0000-0000-000000000004',
          title: 'Your first loop',
          status: CatalogPublishStatus.draft,
          order: 1,
          estimatedMinutes: 20,
          durationSeconds: 180,
          videoProvider: 'fixture',
          videoRef: 'fixture://loop',
        ),
      ],
    ),
  ];

  AuthoringSubject _requireSubjectByVersion(String subjectVersionId) {
    return _subjects.firstWhere(
      (s) => s.subjectVersionId == subjectVersionId,
      orElse: () => throw StateError('Unknown subject version.'),
    );
  }

  AuthoringSubject _requireSubjectById(String subjectId) {
    return _subjects.firstWhere(
      (s) => s.subjectId == subjectId,
      orElse: () => throw StateError('Unknown subject.'),
    );
  }

  int _indexOf(AuthoringSubject subject) =>
      _subjects.indexWhere((s) => s.subjectId == subject.subjectId);

  @override
  Future<List<AuthoringSubject>> listSubjects({String query = ''}) async {
    final q = query.trim().toLowerCase();
    final filtered = [
      for (final subject in _subjects)
        if (q.isEmpty ||
            subject.title.toLowerCase().contains(q) ||
            subject.slug.contains(q))
          subject,
    ]..sort((a, b) => a.order.compareTo(b.order));
    return filtered;
  }

  @override
  Future<AuthoringSubject> createSubjectDraft({
    required String slug,
    required String title,
    String summary = '',
    String? titleUr,
    String worldColorHex = '#2F7BFF',
    String track = 'both',
  }) async {
    if (slug.trim().isEmpty || title.trim().isEmpty) {
      throw StateError('Subject slug and title are required.');
    }
    createSubjectCount++;
    final created = AuthoringSubject(
      subjectId: 'subject-$createSubjectCount',
      slug: slug.trim().toLowerCase(),
      subjectVersionId: 'subject-version-$createSubjectCount',
      title: title.trim(),
      titleUr: titleUr,
      summary: summary,
      worldColorHex: worldColorHex,
      status: CatalogPublishStatus.draft,
      order: _subjects.length + 1,
      track: track,
    );
    _subjects.add(created);
    return created;
  }

  @override
  Future<AuthoringSubject> publishSubject(String subjectVersionId) async {
    final current = _requireSubjectByVersion(subjectVersionId);
    if (!LearningContentPublishPolicy.subjectReady(current)) {
      throw StateError('Subject title is required before publish.');
    }
    final updated = AuthoringSubject(
      subjectId: current.subjectId,
      slug: current.slug,
      subjectVersionId: current.subjectVersionId,
      version: current.version,
      title: current.title,
      titleUr: current.titleUr,
      summary: current.summary,
      worldColorHex: current.worldColorHex,
      status: CatalogPublishStatus.published,
      order: current.order,
      track: current.track,
      minGrade: current.minGrade,
      maxGrade: current.maxGrade,
      independentAllowed: current.independentAllowed,
      topics: current.topics,
    );
    _subjects[_indexOf(current)] = updated;
    return updated;
  }

  @override
  Future<AuthoringSubject> archiveSubject(String subjectVersionId) async {
    final current = _requireSubjectByVersion(subjectVersionId);
    if (!current.isPublished) {
      throw StateError('Only published subjects can be archived.');
    }
    final updated = AuthoringSubject(
      subjectId: current.subjectId,
      slug: current.slug,
      subjectVersionId: current.subjectVersionId,
      version: current.version,
      title: current.title,
      titleUr: current.titleUr,
      summary: current.summary,
      worldColorHex: current.worldColorHex,
      status: CatalogPublishStatus.archived,
      order: current.order,
      track: current.track,
      minGrade: current.minGrade,
      maxGrade: current.maxGrade,
      independentAllowed: current.independentAllowed,
      topics: current.topics,
    );
    _subjects[_indexOf(current)] = updated;
    return updated;
  }

  @override
  Future<AuthoringTopic> createTopicDraft({
    required String subjectId,
    required String slug,
    required String title,
    String? titleUr,
    List<String> objectives = const [],
    int estimatedMinutes = 10,
    int durationSeconds = 300,
    String videoProvider = 'fixture',
    String videoRef = 'draft://pending',
    String? requiresTopicId,
  }) async {
    final subject = _requireSubjectById(subjectId);
    if (slug.trim().isEmpty || title.trim().isEmpty) {
      throw StateError('Topic slug and title are required.');
    }
    createTopicCount++;
    final topic = AuthoringTopic(
      topicId: 'topic-$createTopicCount',
      slug: slug.trim().toLowerCase(),
      topicVersionId: 'topic-version-$createTopicCount',
      title: title.trim(),
      titleUr: titleUr,
      status: CatalogPublishStatus.draft,
      order: subject.topics.length + 1,
      estimatedMinutes: estimatedMinutes,
      durationSeconds: durationSeconds,
      videoProvider: videoProvider,
      videoRef: videoRef,
      objectives: objectives,
    );
    final updated = AuthoringSubject(
      subjectId: subject.subjectId,
      slug: subject.slug,
      subjectVersionId: subject.subjectVersionId,
      version: subject.version,
      title: subject.title,
      titleUr: subject.titleUr,
      summary: subject.summary,
      worldColorHex: subject.worldColorHex,
      status: subject.status,
      order: subject.order,
      track: subject.track,
      minGrade: subject.minGrade,
      maxGrade: subject.maxGrade,
      independentAllowed: subject.independentAllowed,
      topics: [...subject.topics, topic],
    );
    _subjects[_indexOf(subject)] = updated;
    return topic;
  }

  @override
  Future<AuthoringTopic> publishTopic(String topicVersionId) async {
    for (var i = 0; i < _subjects.length; i++) {
      final subject = _subjects[i];
      final index =
          subject.topics.indexWhere((t) => t.topicVersionId == topicVersionId);
      if (index == -1) continue;
      if (!subject.isPublished) {
        throw StateError(
          'Publish the subject version before publishing its topics.',
        );
      }
      final topic = subject.topics[index];
      if (!LearningContentPublishPolicy.topicReady(topic)) {
        throw StateError(
          'Topic publish requires title and valid video media metadata.',
        );
      }
      final published = AuthoringTopic(
        topicId: topic.topicId,
        slug: topic.slug,
        topicVersionId: topic.topicVersionId,
        version: topic.version,
        title: topic.title,
        titleUr: topic.titleUr,
        status: CatalogPublishStatus.published,
        order: topic.order,
        estimatedMinutes: topic.estimatedMinutes,
        durationSeconds: topic.durationSeconds,
        videoProvider: topic.videoProvider,
        videoRef: topic.videoRef,
        objectives: topic.objectives,
      );
      final nextTopics = [...subject.topics];
      nextTopics[index] = published;
      _subjects[i] = AuthoringSubject(
        subjectId: subject.subjectId,
        slug: subject.slug,
        subjectVersionId: subject.subjectVersionId,
        version: subject.version,
        title: subject.title,
        titleUr: subject.titleUr,
        summary: subject.summary,
        worldColorHex: subject.worldColorHex,
        status: subject.status,
        order: subject.order,
        track: subject.track,
        minGrade: subject.minGrade,
        maxGrade: subject.maxGrade,
        independentAllowed: subject.independentAllowed,
        topics: nextTopics,
      );
      return published;
    }
    throw StateError('Unknown topic version.');
  }

  @override
  Future<AuthoringTopic> archiveTopic(String topicVersionId) async {
    for (var i = 0; i < _subjects.length; i++) {
      final subject = _subjects[i];
      final index =
          subject.topics.indexWhere((t) => t.topicVersionId == topicVersionId);
      if (index == -1) continue;
      final topic = subject.topics[index];
      if (!topic.isPublished) {
        throw StateError('Only published topics can be archived.');
      }
      final archived = AuthoringTopic(
        topicId: topic.topicId,
        slug: topic.slug,
        topicVersionId: topic.topicVersionId,
        version: topic.version,
        title: topic.title,
        titleUr: topic.titleUr,
        status: CatalogPublishStatus.archived,
        order: topic.order,
        estimatedMinutes: topic.estimatedMinutes,
        durationSeconds: topic.durationSeconds,
        videoProvider: topic.videoProvider,
        videoRef: topic.videoRef,
        objectives: topic.objectives,
      );
      final nextTopics = [...subject.topics];
      nextTopics[index] = archived;
      _subjects[i] = AuthoringSubject(
        subjectId: subject.subjectId,
        slug: subject.slug,
        subjectVersionId: subject.subjectVersionId,
        version: subject.version,
        title: subject.title,
        titleUr: subject.titleUr,
        summary: subject.summary,
        worldColorHex: subject.worldColorHex,
        status: subject.status,
        order: subject.order,
        track: subject.track,
        minGrade: subject.minGrade,
        maxGrade: subject.maxGrade,
        independentAllowed: subject.independentAllowed,
        topics: nextTopics,
      );
      return archived;
    }
    throw StateError('Unknown topic version.');
  }
}

class SupabaseLearningContentRepository implements LearningContentRepository {
  SupabaseLearningContentRepository(this._client);

  final SupabaseClient _client;

  Future<AuthoringSubject?> _findSubject(String subjectVersionId) async {
    final rows = await listSubjects();
    for (final subject in rows) {
      if (subject.subjectVersionId == subjectVersionId) return subject;
    }
    return null;
  }

  Future<AuthoringTopic?> _findTopic(String topicVersionId) async {
    final rows = await listSubjects();
    for (final subject in rows) {
      for (final topic in subject.topics) {
        if (topic.topicVersionId == topicVersionId) return topic;
      }
    }
    return null;
  }

  @override
  Future<List<AuthoringSubject>> listSubjects({String query = ''}) async {
    final raw = await _client.from('learning_authoring').select();
    final subjects = [
      for (final row in (raw as List).whereType<Map>())
        AuthoringSubject.fromJson(Map<String, dynamic>.from(row)),
    ];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return subjects;
    return [
      for (final subject in subjects)
        if (subject.title.toLowerCase().contains(q) ||
            subject.slug.contains(q))
          subject,
    ];
  }

  @override
  Future<AuthoringSubject> createSubjectDraft({
    required String slug,
    required String title,
    String summary = '',
    String? titleUr,
    String worldColorHex = '#2F7BFF',
    String track = 'both',
  }) async {
    final raw = await _client.rpc(
      'create_subject_draft',
      params: {
        'p_slug': slug,
        'p_title': title,
        'p_summary': summary,
        'p_title_ur': titleUr,
        'p_world_color_hex': worldColorHex,
        'p_track': track,
      },
    );
    return AuthoringSubject.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<AuthoringSubject> publishSubject(String subjectVersionId) async {
    await _client.rpc(
      'publish_subject_version',
      params: {'p_version_id': subjectVersionId},
    );
    return (await _findSubject(subjectVersionId))!;
  }

  @override
  Future<AuthoringSubject> archiveSubject(String subjectVersionId) async {
    await _client.rpc(
      'archive_subject_version',
      params: {'p_version_id': subjectVersionId},
    );
    return (await _findSubject(subjectVersionId))!;
  }

  @override
  Future<AuthoringTopic> createTopicDraft({
    required String subjectId,
    required String slug,
    required String title,
    String? titleUr,
    List<String> objectives = const [],
    int estimatedMinutes = 10,
    int durationSeconds = 300,
    String videoProvider = 'fixture',
    String videoRef = 'draft://pending',
    String? requiresTopicId,
  }) async {
    final raw = await _client.rpc(
      'create_topic_draft',
      params: {
        'p_subject_id': subjectId,
        'p_slug': slug,
        'p_title': title,
        'p_title_ur': titleUr,
        'p_objectives': objectives,
        'p_estimated_minutes': estimatedMinutes,
        'p_duration_seconds': durationSeconds,
        'p_video_provider': videoProvider,
        'p_video_ref': videoRef,
        'p_requires_topic_id': requiresTopicId,
      },
    );
    return AuthoringTopic.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<AuthoringTopic> publishTopic(String topicVersionId) async {
    await _client.rpc(
      'publish_topic_version',
      params: {'p_version_id': topicVersionId},
    );
    return (await _findTopic(topicVersionId))!;
  }

  @override
  Future<AuthoringTopic> archiveTopic(String topicVersionId) async {
    await _client.rpc(
      'archive_topic_version',
      params: {'p_version_id': topicVersionId},
    );
    return (await _findTopic(topicVersionId))!;
  }
}
