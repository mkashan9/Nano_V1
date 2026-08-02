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
                gameId: 'g-number',
                versionId: 'v-number',
                slug: 'number_rush',
                category: GameCategory.practice,
                titleEn: 'Number Rush',
                summaryEn: 'Practice counting under a gentle timer.',
                sortOrder: 10,
                minGrade: 1,
                maxGrade: 5,
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
