import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Curator access to the platform question bank.
abstract class QuestionBankRepository {
  Future<List<QuestionVersion>> listQuestions({String? query});

  Future<QuestionVersion> createDraft({
    required String slug,
    required String stem,
    required List<QuestionOption> options,
    QuestionKind kind = QuestionKind.multipleChoice,
    String? stemUr,
    String explanation = '',
    String? explanationUr,
    QuestionDifficulty difficulty = QuestionDifficulty.easy,
    String localePolicy = 'both',
    String provenance = '',
    String? questionId,
  });

  Future<QuestionVersion> publish(String questionVersionId);

  Future<QuestionVersion> retire(String questionVersionId);
}

class FakeQuestionBankRepository implements QuestionBankRepository {
  FakeQuestionBankRepository({
    this.alwaysFail = false,
    List<QuestionVersion>? seed,
  }) : _items = [
          ...?seed,
          if (seed == null) ..._defaultSeed,
        ];

  final bool alwaysFail;
  final List<QuestionVersion> _items;
  var createCount = 0;
  var publishCount = 0;
  var retireCount = 0;

  static final _defaultSeed = <QuestionVersion>[
    QuestionVersion(
      id: '51000000-0000-0000-0000-000000000001',
      questionId: '50000000-0000-0000-0000-000000000001',
      slug: 'counting-how-many',
      status: QuestionStatus.published,
      stem: 'How many apples are in the basket if you count to five?',
      stemUr: 'اگر آپ پانچ تک گنتی کریں تو ٹوکری میں کتنے سیب ہیں؟',
      options: const [
        QuestionOption(id: 'a', label: 'Three', labelUr: 'تین'),
        QuestionOption(id: 'b', label: 'Five', labelUr: 'پانچ', isCorrect: true),
        QuestionOption(id: 'c', label: 'Ten', labelUr: 'دس'),
      ],
      explanation: 'Counting to five means there are five.',
      explanationUr: 'پانچ تک گنتی کا مطلب ہے پانچ۔',
      difficulty: QuestionDifficulty.easy,
      provenance: 'seed: counting to 20',
      publishedAt: DateTime.utc(2026, 8, 1),
    ),
    QuestionVersion(
      id: '51000000-0000-0000-0000-000000000002',
      questionId: '50000000-0000-0000-0000-000000000002',
      slug: 'addition-two-plus-three',
      status: QuestionStatus.published,
      stem: 'What is 2 + 3?',
      stemUr: '2 + 3 کیا ہے؟',
      options: const [
        QuestionOption(id: 'a', label: '4'),
        QuestionOption(id: 'b', label: '5', isCorrect: true),
        QuestionOption(id: 'c', label: '6'),
      ],
      explanation: 'Two plus three is five.',
      difficulty: QuestionDifficulty.easy,
      provenance: 'seed: adding small numbers',
      publishedAt: DateTime.utc(2026, 8, 1),
    ),
    QuestionVersion(
      id: '51000000-0000-0000-0000-000000000003',
      questionId: '50000000-0000-0000-0000-000000000003',
      slug: 'living-things-breathe',
      status: QuestionStatus.published,
      kind: QuestionKind.trueFalse,
      stem: 'Do living things need air?',
      stemUr: 'کیا جانداروں کو ہوا کی ضرورت ہوتی ہے؟',
      options: const [
        QuestionOption(id: 'yes', label: 'Yes', labelUr: 'ہاں', isCorrect: true),
        QuestionOption(id: 'no', label: 'No', labelUr: 'نہیں'),
      ],
      explanation: 'Living things need air to breathe.',
      difficulty: QuestionDifficulty.easy,
      provenance: 'seed: living things',
      publishedAt: DateTime.utc(2026, 8, 1),
    ),
  ];

  @override
  Future<List<QuestionVersion>> listQuestions({String? query}) async {
    if (alwaysFail) throw StateError('Question bank unavailable');
    final needle = query?.trim().toLowerCase() ?? '';
    final filtered = needle.isEmpty
        ? [..._items]
        : _items
            .where(
              (item) =>
                  item.stem.toLowerCase().contains(needle) ||
                  item.slug.contains(needle),
            )
            .toList();
    filtered.sort((a, b) => a.slug.compareTo(b.slug));
    return filtered;
  }

  @override
  Future<QuestionVersion> createDraft({
    required String slug,
    required String stem,
    required List<QuestionOption> options,
    QuestionKind kind = QuestionKind.multipleChoice,
    String? stemUr,
    String explanation = '',
    String? explanationUr,
    QuestionDifficulty difficulty = QuestionDifficulty.easy,
    String localePolicy = 'both',
    String provenance = '',
    String? questionId,
  }) async {
    if (alwaysFail) throw StateError('Question bank unavailable');
    if (!QuestionPreviewPolicy.optionsValid(kind: kind, options: options)) {
      throw ArgumentError('Invalid options');
    }
    createCount++;
    final normalized = QuestionPreviewPolicy.normalizeStem(stem);
    final duplicates = [
      for (final item in _items)
        if (QuestionPreviewPolicy.normalizeStem(item.stem) == normalized)
          QuestionDuplicate(
            questionId: item.questionId,
            questionVersionId: item.id,
            slug: item.slug,
            stem: item.stem,
            status: item.status,
            version: item.version,
          ),
    ];
    final id = 'draft-${createCount.toString().padLeft(4, '0')}';
    final qid = questionId ?? 'question-$createCount';
    final version = QuestionVersion(
      id: id,
      questionId: qid,
      slug: slug.trim().toLowerCase(),
      version: questionId == null
          ? 1
          : (_items
                  .where((item) => item.questionId == questionId)
                  .map((item) => item.version)
                  .fold<int>(0, (a, b) => a > b ? a : b) +
              1),
      status: QuestionStatus.draft,
      kind: kind,
      stem: stem.trim(),
      stemUr: stemUr,
      options: options,
      explanation: explanation,
      explanationUr: explanationUr,
      difficulty: difficulty,
      localePolicy: localePolicy,
      provenance: provenance,
      stemHash: normalized,
      duplicates: duplicates,
    );
    _items.add(version);
    return version;
  }

  @override
  Future<QuestionVersion> publish(String questionVersionId) async {
    if (alwaysFail) throw StateError('Question bank unavailable');
    publishCount++;
    final index = _items.indexWhere((item) => item.id == questionVersionId);
    if (index < 0) throw StateError('Unknown question version');
    final current = _items[index];
    if (current.status == QuestionStatus.published) return current;
    if (current.status != QuestionStatus.draft) {
      throw StateError('Only drafts can be published');
    }
    // Retire prior published versions of the same question.
    for (var i = 0; i < _items.length; i++) {
      final item = _items[i];
      if (item.questionId == current.questionId &&
          item.status == QuestionStatus.published &&
          item.id != current.id) {
        _items[i] = QuestionVersion(
          id: item.id,
          questionId: item.questionId,
          slug: item.slug,
          version: item.version,
          status: QuestionStatus.retired,
          kind: item.kind,
          stem: item.stem,
          stemUr: item.stemUr,
          options: item.options,
          explanation: item.explanation,
          explanationUr: item.explanationUr,
          difficulty: item.difficulty,
          localePolicy: item.localePolicy,
          provenance: item.provenance,
          stemHash: item.stemHash,
          publishedAt: item.publishedAt,
          publishedBy: item.publishedBy,
        );
      }
    }
    final published = QuestionVersion(
      id: current.id,
      questionId: current.questionId,
      slug: current.slug,
      version: current.version,
      status: QuestionStatus.published,
      kind: current.kind,
      stem: current.stem,
      stemUr: current.stemUr,
      options: current.options,
      explanation: current.explanation,
      explanationUr: current.explanationUr,
      difficulty: current.difficulty,
      localePolicy: current.localePolicy,
      provenance: current.provenance,
      stemHash: current.stemHash,
      publishedAt: DateTime.now().toUtc(),
      publishedBy: 'platform-admin',
    );
    _items[index] = published;
    return published;
  }

  @override
  Future<QuestionVersion> retire(String questionVersionId) async {
    if (alwaysFail) throw StateError('Question bank unavailable');
    retireCount++;
    final index = _items.indexWhere((item) => item.id == questionVersionId);
    if (index < 0) throw StateError('Unknown question version');
    final current = _items[index];
    if (current.status == QuestionStatus.retired) return current;
    if (current.status != QuestionStatus.published) {
      throw StateError('Only published versions can be retired');
    }
    final retired = QuestionVersion(
      id: current.id,
      questionId: current.questionId,
      slug: current.slug,
      version: current.version,
      status: QuestionStatus.retired,
      kind: current.kind,
      stem: current.stem,
      stemUr: current.stemUr,
      options: current.options,
      explanation: current.explanation,
      explanationUr: current.explanationUr,
      difficulty: current.difficulty,
      localePolicy: current.localePolicy,
      provenance: current.provenance,
      stemHash: current.stemHash,
      publishedAt: current.publishedAt,
      publishedBy: current.publishedBy,
    );
    _items[index] = retired;
    return retired;
  }
}

class SupabaseQuestionBankRepository implements QuestionBankRepository {
  SupabaseQuestionBankRepository(this._client);

  static const _columns =
      'question_id, slug, question_version_id, version, status, kind, stem, '
      'stem_ur, options, explanation, explanation_ur, difficulty, '
      'locale_policy, media, provenance, stem_hash, published_at, published_by';

  final SupabaseClient _client;

  @override
  Future<List<QuestionVersion>> listQuestions({String? query}) async {
    final rows = await _client
        .from('question_bank')
        .select(_columns)
        .order('slug');
    final items = [
      for (final row in rows as List)
        QuestionVersion.fromRow(Map<String, dynamic>.from(row as Map)),
    ];
    final needle = query?.trim().toLowerCase() ?? '';
    if (needle.isEmpty) return items;
    return items
        .where(
          (item) =>
              item.stem.toLowerCase().contains(needle) ||
              item.slug.contains(needle),
        )
        .toList();
  }

  @override
  Future<QuestionVersion> createDraft({
    required String slug,
    required String stem,
    required List<QuestionOption> options,
    QuestionKind kind = QuestionKind.multipleChoice,
    String? stemUr,
    String explanation = '',
    String? explanationUr,
    QuestionDifficulty difficulty = QuestionDifficulty.easy,
    String localePolicy = 'both',
    String provenance = '',
    String? questionId,
  }) async {
    final result = await _client.rpc(
      'create_question_draft',
      params: {
        'p_slug': slug,
        'p_stem': stem,
        'p_options': [for (final option in options) option.toRow()],
        'p_kind': kind.wireName,
        'p_stem_ur': stemUr,
        'p_explanation': explanation,
        'p_explanation_ur': explanationUr,
        'p_difficulty': difficulty.wireName,
        'p_locale_policy': localePolicy,
        'p_media': <Map<String, dynamic>>[],
        'p_provenance': provenance,
        'p_question_id': questionId,
      },
    );
    final map = Map<String, dynamic>.from(result as Map);
    map['slug'] = slug.trim().toLowerCase();
    return QuestionVersion.fromRow(map);
  }

  @override
  Future<QuestionVersion> publish(String questionVersionId) async {
    final row = await _client.rpc(
      'publish_question_version',
      params: {'p_version_id': questionVersionId},
    );
    final map = Map<String, dynamic>.from(row as Map);
    map['question_version_id'] = map['id'];
    return QuestionVersion.fromRow(map);
  }

  @override
  Future<QuestionVersion> retire(String questionVersionId) async {
    final row = await _client.rpc(
      'retire_question_version',
      params: {'p_version_id': questionVersionId},
    );
    final map = Map<String, dynamic>.from(row as Map);
    map['question_version_id'] = map['id'];
    return QuestionVersion.fromRow(map);
  }
}
