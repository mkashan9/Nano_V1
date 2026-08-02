/// GME-01 learner-visible game catalog models.
enum GameCategory {
  practice,
  challenge,
  world;

  static GameCategory parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'challenge':
        return GameCategory.challenge;
      case 'world':
        return GameCategory.world;
      case 'practice':
      default:
        return GameCategory.practice;
    }
  }

  String get wire => name;
}

enum GameEntryKind {
  web,
  flutter;

  static GameEntryKind parse(String? raw) {
    switch ((raw ?? '').toLowerCase().trim()) {
      case 'flutter':
        return GameEntryKind.flutter;
      case 'web':
      default:
        return GameEntryKind.web;
    }
  }

  String get wire => name;
}

class CatalogGame {
  const CatalogGame({
    required this.gameId,
    required this.versionId,
    required this.slug,
    required this.category,
    required this.titleEn,
    required this.summaryEn,
    this.titleUr = '',
    this.summaryUr = '',
    this.sortOrder = 100,
    this.version = 1,
    this.minGrade,
    this.maxGrade,
    this.entryKind = GameEntryKind.web,
    this.entryRef = '',
    this.independentAllowed = true,
  });

  final String gameId;
  final String versionId;
  final String slug;
  final GameCategory category;
  final String titleEn;
  final String titleUr;
  final String summaryEn;
  final String summaryUr;
  final int sortOrder;
  final int version;
  final int? minGrade;
  final int? maxGrade;
  final GameEntryKind entryKind;
  final String entryRef;
  final bool independentAllowed;

  String titleFor(bool urdu) =>
      urdu && titleUr.trim().isNotEmpty ? titleUr : titleEn;

  String summaryFor(bool urdu) =>
      urdu && summaryUr.trim().isNotEmpty ? summaryUr : summaryEn;

  factory CatalogGame.fromJson(Map<String, dynamic> json) {
    return CatalogGame(
      gameId: json['game_id'] as String? ?? '',
      versionId: json['version_id'] as String? ?? '',
      slug: json['slug'] as String? ?? '',
      category: GameCategory.parse(json['category'] as String?),
      titleEn: json['title_en'] as String? ?? '',
      titleUr: json['title_ur'] as String? ?? '',
      summaryEn: json['summary_en'] as String? ?? '',
      summaryUr: json['summary_ur'] as String? ?? '',
      sortOrder: (json['sort_order'] as num?)?.toInt() ?? 100,
      version: (json['version'] as num?)?.toInt() ?? 1,
      minGrade: (json['min_grade'] as num?)?.toInt(),
      maxGrade: (json['max_grade'] as num?)?.toInt(),
      entryKind: GameEntryKind.parse(json['entry_kind'] as String?),
      entryRef: json['entry_ref'] as String? ?? '',
      independentAllowed: json['independent_allowed'] as bool? ?? true,
    );
  }
}

class GameCatalog {
  const GameCatalog({
    required this.games,
    this.generatedAt,
  });

  final List<CatalogGame> games;
  final DateTime? generatedAt;

  bool get isEmpty => games.isEmpty;

  factory GameCatalog.fromJson(Map<String, dynamic> json) {
    final rows = json['games'];
    return GameCatalog(
      games: [
        if (rows is List)
          for (final row in rows.whereType<Map>())
            CatalogGame.fromJson(Map<String, dynamic>.from(row)),
      ],
      generatedAt: json['generated_at'] == null
          ? null
          : DateTime.tryParse('${json['generated_at']}'),
    );
  }
}

/// Client-side mirror of server eligibility (fake repos / tests only).
abstract final class GameEligibility {
  static bool allows({
    required CatalogGame game,
    required bool independent,
    int? gradeLevel,
  }) {
    if (independent && !game.independentAllowed) return false;
    final grade = gradeLevel;
    if (grade != null) {
      if (game.minGrade != null && grade < game.minGrade!) return false;
      if (game.maxGrade != null && grade > game.maxGrade!) return false;
    }
    return true;
  }
}
