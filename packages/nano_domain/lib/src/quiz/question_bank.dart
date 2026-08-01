import '../l10n/nano_app_locale.dart';

/// How a question is answered.
enum QuestionKind {
  multipleChoice,
  trueFalse;

  static QuestionKind fromName(String? name) => switch (name) {
        'true_false' => QuestionKind.trueFalse,
        _ => QuestionKind.multipleChoice,
      };

  String get wireName => switch (this) {
        QuestionKind.multipleChoice => 'multiple_choice',
        QuestionKind.trueFalse => 'true_false',
      };
}

/// Draft → published → retired. Published and retired are immutable.
enum QuestionStatus {
  draft,
  published,
  retired;

  static QuestionStatus fromName(String? name) => switch (name) {
        'published' => QuestionStatus.published,
        'retired' => QuestionStatus.retired,
        _ => QuestionStatus.draft,
      };

  String get wireName => name;

  bool get isEditable => this == QuestionStatus.draft;
}

enum QuestionDifficulty {
  easy,
  medium,
  hard;

  static QuestionDifficulty fromName(String? name) => switch (name) {
        'medium' => QuestionDifficulty.medium,
        'hard' => QuestionDifficulty.hard,
        _ => QuestionDifficulty.easy,
      };

  String get wireName => name;
}

/// One answer choice. Correctness is curator-only; learner projections drop it.
class QuestionOption {
  const QuestionOption({
    required this.id,
    required this.label,
    this.labelUr,
    this.isCorrect = false,
  });

  factory QuestionOption.fromRow(Map<String, dynamic> row) {
    return QuestionOption(
      id: (row['id'] as String?) ?? '',
      label: (row['label'] as String?) ?? '',
      labelUr: row['label_ur'] as String?,
      isCorrect: row['is_correct'] == true,
    );
  }

  final String id;
  final String label;
  final String? labelUr;
  final bool isCorrect;

  String labelFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (labelUr?.isNotEmpty ?? false)
          ? labelUr!
          : label;

  Map<String, dynamic> toRow() => {
        'id': id,
        'label': label,
        if (labelUr != null) 'label_ur': labelUr,
        'is_correct': isCorrect,
      };

  /// Learner-safe projection: no correctness flag.
  Map<String, dynamic> toLearnerRow() => {
        'id': id,
        'label': label,
        if (labelUr != null) 'label_ur': labelUr,
      };
}

/// A version of a question from the bank.
class QuestionVersion {
  const QuestionVersion({
    required this.id,
    required this.questionId,
    required this.slug,
    this.version = 1,
    this.status = QuestionStatus.draft,
    this.kind = QuestionKind.multipleChoice,
    required this.stem,
    this.stemUr,
    this.options = const [],
    this.explanation = '',
    this.explanationUr,
    this.difficulty = QuestionDifficulty.easy,
    this.localePolicy = 'both',
    this.provenance = '',
    this.stemHash = '',
    this.publishedAt,
    this.publishedBy,
    this.duplicates = const [],
  });

  factory QuestionVersion.fromRow(Map<String, dynamic> row) {
    final optionsRaw = row['options'];
    final options = <QuestionOption>[];
    if (optionsRaw is List) {
      for (final item in optionsRaw) {
        if (item is Map) {
          options.add(
            QuestionOption.fromRow(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    final duplicatesRaw = row['duplicates'];
    final duplicates = <QuestionDuplicate>[];
    if (duplicatesRaw is List) {
      for (final item in duplicatesRaw) {
        if (item is Map) {
          duplicates.add(
            QuestionDuplicate.fromRow(Map<String, dynamic>.from(item)),
          );
        }
      }
    }
    return QuestionVersion(
      id: (row['question_version_id'] as String?) ??
          (row['id'] as String?) ??
          '',
      questionId: (row['question_id'] as String?) ?? '',
      slug: (row['slug'] as String?) ?? '',
      version: (row['version'] as num?)?.toInt() ?? 1,
      status: QuestionStatus.fromName(row['status'] as String?),
      kind: QuestionKind.fromName(row['kind'] as String?),
      stem: (row['stem'] as String?) ?? '',
      stemUr: row['stem_ur'] as String?,
      options: options,
      explanation: (row['explanation'] as String?) ?? '',
      explanationUr: row['explanation_ur'] as String?,
      difficulty: QuestionDifficulty.fromName(row['difficulty'] as String?),
      localePolicy: (row['locale_policy'] as String?) ?? 'both',
      provenance: (row['provenance'] as String?) ?? '',
      stemHash: (row['stem_hash'] as String?) ?? '',
      publishedAt: switch (row['published_at']) {
        final String value => DateTime.tryParse(value)?.toUtc(),
        final DateTime value => value.toUtc(),
        _ => null,
      },
      publishedBy: row['published_by'] as String?,
      duplicates: duplicates,
    );
  }

  final String id;
  final String questionId;
  final String slug;
  final int version;
  final QuestionStatus status;
  final QuestionKind kind;
  final String stem;
  final String? stemUr;
  final List<QuestionOption> options;
  final String explanation;
  final String? explanationUr;
  final QuestionDifficulty difficulty;
  final String localePolicy;
  final String provenance;
  final String stemHash;
  final DateTime? publishedAt;
  final String? publishedBy;
  final List<QuestionDuplicate> duplicates;

  String stemFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (stemUr?.isNotEmpty ?? false)
          ? stemUr!
          : stem;

  String explanationFor(NanoAppLocale locale) =>
      locale == NanoAppLocale.ur && (explanationUr?.isNotEmpty ?? false)
          ? explanationUr!
          : explanation;

  bool get hasDuplicates => duplicates.isNotEmpty;

  QuestionOption? get correctOption {
    for (final option in options) {
      if (option.isCorrect) return option;
    }
    return null;
  }
}

/// Another bank entry that shares a normalized stem.
class QuestionDuplicate {
  const QuestionDuplicate({
    required this.questionId,
    required this.questionVersionId,
    required this.slug,
    required this.stem,
    required this.status,
    this.version = 1,
  });

  factory QuestionDuplicate.fromRow(Map<String, dynamic> row) {
    return QuestionDuplicate(
      questionId: (row['question_id'] as String?) ?? '',
      questionVersionId: (row['question_version_id'] as String?) ?? '',
      slug: (row['slug'] as String?) ?? '',
      stem: (row['stem'] as String?) ?? '',
      status: QuestionStatus.fromName(row['status'] as String?),
      version: (row['version'] as num?)?.toInt() ?? 1,
    );
  }

  final String questionId;
  final String questionVersionId;
  final String slug;
  final String stem;
  final QuestionStatus status;
  final int version;
}

/// Shared preview rules so Junior and Senior curator previews stay aligned
/// with the student shells that arrive in QZ-03 / QZ-04.
abstract final class QuestionPreviewPolicy {
  /// Normalize a stem the same way the server hashes it.
  static String normalizeStem(String stem) =>
      stem.trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ');

  static bool optionsValid({
    required QuestionKind kind,
    required List<QuestionOption> options,
  }) {
    if (options.any((o) => o.id.isEmpty || o.label.trim().isEmpty)) {
      return false;
    }
    final correct = options.where((o) => o.isCorrect).length;
    if (correct != 1) return false;
    if (kind == QuestionKind.trueFalse && options.length != 2) return false;
    if (kind == QuestionKind.multipleChoice && options.length < 2) return false;
    return true;
  }
}
