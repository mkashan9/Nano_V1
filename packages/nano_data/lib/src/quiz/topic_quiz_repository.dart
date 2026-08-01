import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

import 'question_bank_repository.dart';

/// Curator access to quizzes attached to topic versions.
abstract class TopicQuizRepository {
  Future<List<TopicQuiz>> listQuizzes({String? query});

  Future<TopicQuiz> createDraft({
    required String topicVersionId,
    required String title,
    required List<String> questionVersionIds,
    String? titleUr,
    QuizPolicy policy = const QuizPolicy(),
  });

  Future<TopicQuiz> publish(String quizVersionId);

  Future<TopicQuiz> retire(String quizVersionId);
}

class FakeTopicQuizRepository implements TopicQuizRepository {
  FakeTopicQuizRepository({
    this.alwaysFail = false,
    List<TopicQuiz>? seed,
  }) : _items = [...?seed, if (seed == null) ..._defaultSeed];

  final bool alwaysFail;
  final List<TopicQuiz> _items;
  var createCount = 0;
  var publishCount = 0;
  var retireCount = 0;

  static final _defaultSeed = <TopicQuiz>[
    TopicQuiz(
      id: '60000000-0000-0000-0000-000000000001',
      topicVersionId: '40000000-0000-0000-0000-000000000001',
      topicSlug: 'counting',
      topicTitle: 'Counting to 20',
      status: QuestionStatus.published,
      title: 'Counting check',
      titleUr: 'گنتی کی جانچ',
      publishedAt: DateTime.utc(2026, 8, 1),
      items: const [
        QuizItem(
          sortOrder: 1,
          questionVersionId: '51000000-0000-0000-0000-000000000001',
          stem: 'How many apples are in the basket if you count to five?',
          stemUr: 'اگر آپ پانچ تک گنتی کریں تو ٹوکری میں کتنے سیب ہیں؟',
          options: [
            QuestionOption(id: 'a', label: 'Three', labelUr: 'تین'),
            QuestionOption(
              id: 'b',
              label: 'Five',
              labelUr: 'پانچ',
              isCorrect: true,
            ),
            QuestionOption(id: 'c', label: 'Ten', labelUr: 'دس'),
          ],
        ),
      ],
    ),
    TopicQuiz(
      id: '60000000-0000-0000-0000-000000000002',
      topicVersionId: '40000000-0000-0000-0000-000000000002',
      topicSlug: 'addition',
      topicTitle: 'Adding small numbers',
      status: QuestionStatus.published,
      title: 'Addition check',
      items: const [
        QuizItem(
          sortOrder: 1,
          questionVersionId: '51000000-0000-0000-0000-000000000002',
          stem: 'What is 2 + 3?',
          options: [
            QuestionOption(id: 'a', label: '4'),
            QuestionOption(id: 'b', label: '5', isCorrect: true),
            QuestionOption(id: 'c', label: '6'),
          ],
        ),
      ],
    ),
    TopicQuiz(
      id: '60000000-0000-0000-0000-000000000003',
      topicVersionId: '40000000-0000-0000-0000-000000000003',
      topicSlug: 'living-things',
      topicTitle: 'Living things',
      status: QuestionStatus.published,
      title: 'Living things check',
      items: const [
        QuizItem(
          sortOrder: 1,
          questionVersionId: '51000000-0000-0000-0000-000000000003',
          kind: QuestionKind.trueFalse,
          stem: 'Do living things need air?',
          options: [
            QuestionOption(id: 'yes', label: 'Yes', isCorrect: true),
            QuestionOption(id: 'no', label: 'No'),
          ],
        ),
      ],
    ),
  ];

  @override
  Future<List<TopicQuiz>> listQuizzes({String? query}) async {
    if (alwaysFail) throw StateError('Quizzes unavailable');
    final needle = query?.trim().toLowerCase() ?? '';
    final filtered = needle.isEmpty
        ? [..._items]
        : _items
            .where(
              (item) =>
                  item.title.toLowerCase().contains(needle) ||
                  item.topicSlug.contains(needle) ||
                  item.topicTitle.toLowerCase().contains(needle),
            )
            .toList();
    filtered.sort((a, b) => a.topicSlug.compareTo(b.topicSlug));
    return filtered;
  }

  @override
  Future<TopicQuiz> createDraft({
    required String topicVersionId,
    required String title,
    required List<String> questionVersionIds,
    String? titleUr,
    QuizPolicy policy = const QuizPolicy(),
  }) async {
    if (alwaysFail) throw StateError('Quizzes unavailable');
    if (questionVersionIds.isEmpty) {
      throw ArgumentError('A quiz needs at least one question');
    }
    createCount++;
    final bank = FakeQuestionBankRepository();
    final questions = await bank.listQuestions();
    final byId = {for (final q in questions) q.id: q};
    final items = <QuizItem>[
      for (var i = 0; i < questionVersionIds.length; i++)
        QuizItem(
          sortOrder: i + 1,
          questionVersionId: questionVersionIds[i],
          stem: byId[questionVersionIds[i]]?.stem ?? 'Question ${i + 1}',
          stemUr: byId[questionVersionIds[i]]?.stemUr,
          kind: byId[questionVersionIds[i]]?.kind ?? QuestionKind.multipleChoice,
          options: byId[questionVersionIds[i]]?.options ?? const [],
          explanation: byId[questionVersionIds[i]]?.explanation ?? '',
        ),
    ];
    final quiz = TopicQuiz(
      id: 'quiz-draft-$createCount',
      topicVersionId: topicVersionId,
      topicSlug: 'topic-$createCount',
      topicTitle: 'Topic $createCount',
      version: 1,
      status: QuestionStatus.draft,
      title: title.trim(),
      titleUr: titleUr,
      policy: policy,
      items: items,
    );
    _items.add(quiz);
    return quiz;
  }

  @override
  Future<TopicQuiz> publish(String quizVersionId) async {
    if (alwaysFail) throw StateError('Quizzes unavailable');
    publishCount++;
    final index = _items.indexWhere((item) => item.id == quizVersionId);
    if (index < 0) throw StateError('Unknown quiz');
    final current = _items[index];
    if (current.status == QuestionStatus.published) return current;
    if (current.status != QuestionStatus.draft) {
      throw StateError('Only drafts can be published');
    }
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.topicVersionId == current.topicVersionId &&
          item.status == QuestionStatus.published &&
          item.id != current.id) {
        _items[i] = TopicQuiz(
          id: item.id,
          topicVersionId: item.topicVersionId,
          topicSlug: item.topicSlug,
          topicTitle: item.topicTitle,
          version: item.version,
          status: QuestionStatus.retired,
          title: item.title,
          titleUr: item.titleUr,
          policy: item.policy,
          items: item.items,
          publishedAt: item.publishedAt,
        );
      }
    }
    final published = TopicQuiz(
      id: current.id,
      topicVersionId: current.topicVersionId,
      topicSlug: current.topicSlug,
      topicTitle: current.topicTitle,
      version: current.version,
      status: QuestionStatus.published,
      title: current.title,
      titleUr: current.titleUr,
      policy: current.policy,
      items: current.items,
      publishedAt: DateTime.now().toUtc(),
    );
    _items[index] = published;
    return published;
  }

  @override
  Future<TopicQuiz> retire(String quizVersionId) async {
    if (alwaysFail) throw StateError('Quizzes unavailable');
    retireCount++;
    final index = _items.indexWhere((item) => item.id == quizVersionId);
    if (index < 0) throw StateError('Unknown quiz');
    final current = _items[index];
    if (current.status != QuestionStatus.published) {
      throw StateError('Only published quizzes can be retired');
    }
    final retired = TopicQuiz(
      id: current.id,
      topicVersionId: current.topicVersionId,
      topicSlug: current.topicSlug,
      topicTitle: current.topicTitle,
      version: current.version,
      status: QuestionStatus.retired,
      title: current.title,
      titleUr: current.titleUr,
      policy: current.policy,
      items: current.items,
      publishedAt: current.publishedAt,
    );
    _items[index] = retired;
    return retired;
  }
}

class SupabaseTopicQuizRepository implements TopicQuizRepository {
  SupabaseTopicQuizRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<TopicQuiz>> listQuizzes({String? query}) async {
    final rows = await _client.from('quiz_authoring').select().order('topic_slug');
    final items = [
      for (final row in rows as List)
        TopicQuiz.fromRow(Map<String, dynamic>.from(row as Map)),
    ];
    final needle = query?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.title.toLowerCase().contains(needle) ||
              item.topicSlug.contains(needle),
        )
        .toList();
  }

  @override
  Future<TopicQuiz> createDraft({
    required String topicVersionId,
    required String title,
    required List<String> questionVersionIds,
    String? titleUr,
    QuizPolicy policy = const QuizPolicy(),
  }) async {
    final result = await _client.rpc(
      'create_quiz_draft',
      params: {
        'p_topic_version_id': topicVersionId,
        'p_title': title,
        'p_items': [
          for (var i = 0; i < questionVersionIds.length; i++)
            {
              'question_version_id': questionVersionIds[i],
              'sort_order': i + 1,
            },
        ],
        'p_title_ur': titleUr,
        'p_pass_percent': policy.passPercent,
        'p_timer_seconds': policy.timerSeconds,
        'p_max_retakes': policy.maxRetakes,
        'p_option_order_policy': policy.optionOrder.wireName,
        'p_question_order_policy': policy.questionOrder.wireName,
        'p_locale_policy': policy.localePolicy,
        'p_experience_policy': policy.experiencePolicy,
      },
    );
    final id = (result as Map)['quiz_version_id'] as String;
    final rows = await _client
        .from('quiz_authoring')
        .select()
        .eq('quiz_version_id', id)
        .limit(1);
    return TopicQuiz.fromRow(
      Map<String, dynamic>.from((rows as List).first as Map),
    );
  }

  @override
  Future<TopicQuiz> publish(String quizVersionId) async {
    await _client.rpc(
      'publish_quiz_version',
      params: {'p_quiz_version_id': quizVersionId},
    );
    final rows = await _client
        .from('quiz_authoring')
        .select()
        .eq('quiz_version_id', quizVersionId)
        .limit(1);
    return TopicQuiz.fromRow(
      Map<String, dynamic>.from((rows as List).first as Map),
    );
  }

  @override
  Future<TopicQuiz> retire(String quizVersionId) async {
    await _client.rpc(
      'retire_quiz_version',
      params: {'p_quiz_version_id': quizVersionId},
    );
    final rows = await _client
        .from('quiz_authoring')
        .select()
        .eq('quiz_version_id', quizVersionId)
        .limit(1);
    return TopicQuiz.fromRow(
      Map<String, dynamic>.from((rows as List).first as Map),
    );
  }
}
