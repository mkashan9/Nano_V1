import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Learner-facing published quizzes (never includes is_correct).
abstract class LearnerQuizRepository {
  Future<TopicQuiz?> quizForTopic(String topicVersionId);
}

class FakeLearnerQuizRepository implements LearnerQuizRepository {
  FakeLearnerQuizRepository({
    this.alwaysFail = false,
    List<TopicQuiz>? seed,
  }) : _items = [
          ...?seed,
          if (seed == null) ..._defaultSeed,
        ];

  final bool alwaysFail;
  final List<TopicQuiz> _items;

  /// Learner-safe seeds: options never carry is_correct.
  static final _defaultSeed = <TopicQuiz>[
    TopicQuiz(
      id: '60000000-0000-0000-0000-000000000001',
      topicVersionId: '40000000-0000-0000-0000-000000000001',
      topicSlug: 'counting',
      topicTitle: 'Counting to 20',
      status: QuestionStatus.published,
      title: 'Counting check',
      titleUr: 'گنتی کی جانچ',
      items: const [
        QuizItem(
          sortOrder: 1,
          questionVersionId: '51000000-0000-0000-0000-000000000001',
          stem: 'How many apples are in the basket if you count to five?',
          stemUr: 'اگر آپ پانچ تک گنتی کریں تو ٹوکری میں کتنے سیب ہیں؟',
          options: [
            QuestionOption(id: 'a', label: 'Three', labelUr: 'تین'),
            QuestionOption(id: 'b', label: 'Five', labelUr: 'پانچ'),
            QuestionOption(id: 'c', label: 'Ten', labelUr: 'دس'),
          ],
        ),
        QuizItem(
          sortOrder: 2,
          questionVersionId: '51000000-0000-0000-0000-000000000002',
          stem: 'What is 2 + 3?',
          stemUr: '۲ + ۳ کیا ہے؟',
          options: [
            QuestionOption(id: 'a', label: '4'),
            QuestionOption(id: 'b', label: '5'),
            QuestionOption(id: 'c', label: '6'),
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
            QuestionOption(id: 'b', label: '5'),
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
            QuestionOption(id: 'yes', label: 'Yes'),
            QuestionOption(id: 'no', label: 'No'),
          ],
        ),
      ],
    ),
  ];

  @override
  Future<TopicQuiz?> quizForTopic(String topicVersionId) async {
    if (alwaysFail) throw StateError('Learner quiz unavailable');
    for (final item in _items) {
      if (item.topicVersionId == topicVersionId &&
          item.status == QuestionStatus.published) {
        if (!item.isLearnerSafe) {
          throw StateError('Learner quiz leaked correctness');
        }
        return item;
      }
    }
    return null;
  }
}

class SupabaseLearnerQuizRepository implements LearnerQuizRepository {
  SupabaseLearnerQuizRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<TopicQuiz?> quizForTopic(String topicVersionId) async {
    final rows = await _client
        .from('learner_quiz')
        .select()
        .eq('topic_version_id', topicVersionId)
        .limit(1);
    final list = rows as List;
    if (list.isEmpty) return null;
    final quiz = TopicQuiz.fromRow(
      Map<String, dynamic>.from(list.first as Map),
    );
    if (!quiz.isLearnerSafe) {
      throw StateError('Learner quiz leaked correctness');
    }
    return quiz;
  }
}
