import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// GME-01 learner game catalog (published + eligible only).
abstract class GameCatalogRepository {
  Future<GameCatalog> loadCatalog({
    bool independent = false,
    int? gradeLevel,
  });
}

class FakeGameCatalogRepository implements GameCatalogRepository {
  FakeGameCatalogRepository({
    List<CatalogGame>? seed,
    this.alwaysFail = false,
  }) : _seed = seed ??
            const [
              CatalogGame(
                gameId: 'g-math-island',
                versionId: 'v-math-island',
                slug: 'math_island',
                category: GameCategory.world,
                titleEn: 'Math Island',
                summaryEn: 'Count and play on a tropical island.',
                sortOrder: 10,
                minGrade: 1,
                maxGrade: 5,
                entryKind: GameEntryKind.flutter,
                entryRef: 'fixture://math_island',
              ),
              CatalogGame(
                gameId: 'g-word-forest',
                versionId: 'v-word-forest',
                slug: 'word_forest',
                category: GameCategory.world,
                titleEn: 'Word Forest',
                summaryEn: 'Letters and words among the trees.',
                sortOrder: 20,
                minGrade: 1,
                maxGrade: 5,
                entryKind: GameEntryKind.flutter,
                entryRef: 'fixture://word_forest',
              ),
              CatalogGame(
                gameId: 'g-science-ocean',
                versionId: 'v-science-ocean',
                slug: 'science_ocean',
                category: GameCategory.world,
                titleEn: 'Science Ocean',
                summaryEn: 'Dive into ocean science play.',
                sortOrder: 30,
                minGrade: 1,
                maxGrade: 5,
                entryKind: GameEntryKind.flutter,
                entryRef: 'fixture://science_ocean',
              ),
              CatalogGame(
                gameId: 'g-puzzle-castle',
                versionId: 'v-puzzle-castle',
                slug: 'puzzle_castle',
                category: GameCategory.world,
                titleEn: 'Puzzle Castle',
                summaryEn: 'Build and puzzle in a fairy castle.',
                sortOrder: 40,
                minGrade: 1,
                maxGrade: 5,
                entryKind: GameEntryKind.flutter,
                entryRef: 'fixture://puzzle_castle',
              ),
              CatalogGame(
                gameId: 'g-number',
                versionId: 'v-number',
                slug: 'number_rush',
                category: GameCategory.practice,
                titleEn: 'Number Rush',
                summaryEn: 'Practice counting under a gentle timer.',
                sortOrder: 50,
                minGrade: 1,
                maxGrade: 5,
                entryRef: 'fixture://number_rush',
              ),
              CatalogGame(
                gameId: 'g-shape',
                versionId: 'v-shape',
                slug: 'shape_sort',
                category: GameCategory.world,
                titleEn: 'Shape Sort',
                summaryEn: 'Sort shapes in a junior world.',
                sortOrder: 60,
                minGrade: 1,
                maxGrade: 3,
                entryKind: GameEntryKind.flutter,
                entryRef: 'fixture://shape_sort',
              ),
              CatalogGame(
                gameId: 'g-circuit',
                versionId: 'v-circuit',
                slug: 'school_circuit',
                category: GameCategory.challenge,
                titleEn: 'School Circuit',
                summaryEn: 'A school-linked challenge for grades 6–12.',
                sortOrder: 15,
                minGrade: 6,
                maxGrade: 12,
                independentAllowed: false,
                entryRef: 'fixture://school_circuit',
              ),
            ];

  final List<CatalogGame> _seed;
  var alwaysFail;

  @override
  Future<GameCatalog> loadCatalog({
    bool independent = false,
    int? gradeLevel,
  }) async {
    if (alwaysFail) throw StateError('Games unavailable');
    final games = [
      for (final g in _seed)
        if (GameEligibility.allows(
          game: g,
          independent: independent,
          gradeLevel: gradeLevel,
        ))
          g,
    ];
    return GameCatalog(
      games: List.unmodifiable(games),
      generatedAt: DateTime.utc(2026, 8, 2),
    );
  }
}

class SupabaseGameCatalogRepository implements GameCatalogRepository {
  SupabaseGameCatalogRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<GameCatalog> loadCatalog({
    bool independent = false,
    int? gradeLevel,
  }) async {
    final raw = await _client.rpc('list_games_for_learner');
    if (raw is! Map) throw StateError('Games unavailable.');
    return GameCatalog.fromJson(Map<String, dynamic>.from(raw));
  }
}
