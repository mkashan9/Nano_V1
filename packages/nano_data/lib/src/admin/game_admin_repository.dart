import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// ADM-06 platform game catalog administration.
abstract class GameAdminRepository {
  Future<List<AdminGame>> listGames({String query = ''});

  Future<AdminGame> createDraft({
    required String slug,
    required String titleEn,
    String titleUr = '',
    String summaryEn = '',
    String summaryUr = '',
    String category = 'practice',
    String entryKind = 'web',
    String entryRef = 'fixture://pending',
    int? minGrade,
    int? maxGrade,
    String? gameId,
  });

  Future<AdminGame> publish(String gameVersionId);

  Future<AdminGame> disable({
    required String gameVersionId,
    required String reason,
  });
}

class FakeGameAdminRepository implements GameAdminRepository {
  FakeGameAdminRepository({List<AdminGame>? seed})
      : _games = List.of(seed ?? _defaultSeed);

  final List<AdminGame> _games;
  var createCount = 0;

  static final _defaultSeed = <AdminGame>[
    AdminGame(
      gameId: '60000000-0000-0000-0000-000000000001',
      slug: 'number_rush',
      category: 'practice',
      sortOrder: 10,
      gameVersionId: '61000000-0000-0000-0000-000000000001',
      titleEn: 'Number Rush',
      titleUr: 'نمبر رش',
      summaryEn: 'Practice counting under a gentle timer.',
      status: CatalogPublishStatus.published,
      enabled: true,
      entryKind: 'web',
      entryRef: 'fixture://number_rush',
      minGrade: 1,
      maxGrade: 5,
      publishedAt: DateTime.utc(2026, 8, 1),
    ),
    AdminGame(
      gameId: '60000000-0000-0000-0000-000000000002',
      slug: 'shape_sort',
      category: 'world',
      sortOrder: 20,
      gameVersionId: '61000000-0000-0000-0000-000000000002',
      titleEn: 'Shape Sort',
      titleUr: 'شکلیں چھانٹو',
      summaryEn: 'Sort shapes in a junior world.',
      status: CatalogPublishStatus.draft,
      enabled: true,
      entryKind: 'flutter',
      entryRef: 'fixture://shape_sort',
      minGrade: 1,
      maxGrade: 3,
    ),
  ];

  int _indexOfVersion(String gameVersionId) =>
      _games.indexWhere((g) => g.gameVersionId == gameVersionId);

  AdminGame _require(String gameVersionId) {
    final index = _indexOfVersion(gameVersionId);
    if (index < 0) throw StateError('Unknown game version.');
    return _games[index];
  }

  @override
  Future<List<AdminGame>> listGames({String query = ''}) async {
    final q = query.trim().toLowerCase();
    final filtered = [
      for (final game in _games)
        if (q.isEmpty ||
            game.titleEn.toLowerCase().contains(q) ||
            game.slug.contains(q))
          game,
    ]..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return filtered;
  }

  @override
  Future<AdminGame> createDraft({
    required String slug,
    required String titleEn,
    String titleUr = '',
    String summaryEn = '',
    String summaryUr = '',
    String category = 'practice',
    String entryKind = 'web',
    String entryRef = 'fixture://pending',
    int? minGrade,
    int? maxGrade,
    String? gameId,
  }) async {
    if (slug.trim().isEmpty || titleEn.trim().isEmpty) {
      throw StateError('Game slug and English title are required.');
    }
    if (gameId != null) {
      final hasDraft = _games.any(
        (g) => g.gameId == gameId && g.isDraft,
      );
      if (hasDraft) {
        throw StateError(
          'This game already has a draft. Publish or disable it first.',
        );
      }
    }
    createCount++;
    final created = AdminGame(
      gameId: gameId ?? 'game-$createCount',
      slug: slug.trim().toLowerCase(),
      category: category,
      sortOrder: (_games.isEmpty ? 0 : _games.last.sortOrder) + 10,
      gameVersionId: 'game-version-$createCount',
      version: gameId == null
          ? 1
          : (_games
                  .where((g) => g.gameId == gameId)
                  .map((g) => g.version)
                  .fold<int>(0, (a, b) => a > b ? a : b) +
              1),
      titleEn: titleEn.trim(),
      titleUr: titleUr,
      summaryEn: summaryEn,
      summaryUr: summaryUr,
      minGrade: minGrade,
      maxGrade: maxGrade,
      status: CatalogPublishStatus.draft,
      enabled: true,
      entryKind: entryKind,
      entryRef: entryRef,
    );
    if (gameId != null) {
      _games.removeWhere((g) => g.gameId == gameId);
    }
    _games.add(created);
    return created;
  }

  @override
  Future<AdminGame> publish(String gameVersionId) async {
    final current = _require(gameVersionId);
    if (!GamePublishPolicy.ready(current)) {
      throw StateError('Publish requires a title and entry reference.');
    }
    if (!current.isDraft && current.isPublished) return current;
    if (!current.isDraft) {
      throw StateError('Only drafts can be published.');
    }
    for (var i = 0; i < _games.length; i++) {
      final game = _games[i];
      if (game.gameId == current.gameId &&
          game.gameVersionId != gameVersionId &&
          game.isPublished) {
        _games[i] = AdminGame(
          gameId: game.gameId,
          slug: game.slug,
          category: game.category,
          sortOrder: game.sortOrder,
          gameVersionId: game.gameVersionId,
          version: game.version,
          titleEn: game.titleEn,
          titleUr: game.titleUr,
          summaryEn: game.summaryEn,
          summaryUr: game.summaryUr,
          minGrade: game.minGrade,
          maxGrade: game.maxGrade,
          status: CatalogPublishStatus.archived,
          enabled: false,
          entryKind: game.entryKind,
          entryRef: game.entryRef,
          publishedAt: game.publishedAt,
        );
      }
    }
    final published = AdminGame(
      gameId: current.gameId,
      slug: current.slug,
      category: current.category,
      sortOrder: current.sortOrder,
      gameVersionId: current.gameVersionId,
      version: current.version,
      titleEn: current.titleEn,
      titleUr: current.titleUr,
      summaryEn: current.summaryEn,
      summaryUr: current.summaryUr,
      minGrade: current.minGrade,
      maxGrade: current.maxGrade,
      status: CatalogPublishStatus.published,
      enabled: true,
      entryKind: current.entryKind,
      entryRef: current.entryRef,
      publishedAt: DateTime.now().toUtc(),
    );
    _games[_indexOfVersion(gameVersionId)] = published;
    return published;
  }

  @override
  Future<AdminGame> disable({
    required String gameVersionId,
    required String reason,
  }) async {
    if (reason.trim().isEmpty) {
      throw StateError('A reason is required to disable a game version.');
    }
    final current = _require(gameVersionId);
    final disabled = AdminGame(
      gameId: current.gameId,
      slug: current.slug,
      category: current.category,
      sortOrder: current.sortOrder,
      gameVersionId: current.gameVersionId,
      version: current.version,
      titleEn: current.titleEn,
      titleUr: current.titleUr,
      summaryEn: current.summaryEn,
      summaryUr: current.summaryUr,
      minGrade: current.minGrade,
      maxGrade: current.maxGrade,
      status: current.isPublished
          ? CatalogPublishStatus.archived
          : current.status,
      enabled: false,
      entryKind: current.entryKind,
      entryRef: current.entryRef,
      publishedAt: current.publishedAt,
    );
    _games[_indexOfVersion(gameVersionId)] = disabled;
    return disabled;
  }
}

class SupabaseGameAdminRepository implements GameAdminRepository {
  SupabaseGameAdminRepository(this._client);

  final SupabaseClient _client;

  Future<AdminGame?> _find(String gameVersionId) async {
    final rows = await listGames();
    for (final game in rows) {
      if (game.gameVersionId == gameVersionId) return game;
    }
    return null;
  }

  @override
  Future<List<AdminGame>> listGames({String query = ''}) async {
    final raw = await _client.rpc('list_games_admin');
    final games = [
      for (final row in (raw as List).whereType<Map>())
        AdminGame.fromJson(Map<String, dynamic>.from(row)),
    ];
    final q = query.trim().toLowerCase();
    if (q.isEmpty) return games;
    return [
      for (final game in games)
        if (game.titleEn.toLowerCase().contains(q) || game.slug.contains(q))
          game,
    ];
  }

  @override
  Future<AdminGame> createDraft({
    required String slug,
    required String titleEn,
    String titleUr = '',
    String summaryEn = '',
    String summaryUr = '',
    String category = 'practice',
    String entryKind = 'web',
    String entryRef = 'fixture://pending',
    int? minGrade,
    int? maxGrade,
    String? gameId,
  }) async {
    final raw = await _client.rpc(
      'create_game_draft',
      params: {
        'p_slug': slug,
        'p_title_en': titleEn,
        'p_title_ur': titleUr,
        'p_summary_en': summaryEn,
        'p_summary_ur': summaryUr,
        'p_category': category,
        'p_entry_kind': entryKind,
        'p_entry_ref': entryRef,
        'p_min_grade': minGrade,
        'p_max_grade': maxGrade,
        'p_game_id': gameId,
      },
    );
    return AdminGame.fromJson(Map<String, dynamic>.from(raw as Map));
  }

  @override
  Future<AdminGame> publish(String gameVersionId) async {
    await _client.rpc(
      'publish_game_version',
      params: {'p_version_id': gameVersionId},
    );
    return (await _find(gameVersionId))!;
  }

  @override
  Future<AdminGame> disable({
    required String gameVersionId,
    required String reason,
  }) async {
    await _client.rpc(
      'disable_game_version',
      params: {
        'p_version_id': gameVersionId,
        'p_reason': reason,
      },
    );
    return (await _find(gameVersionId))!;
  }
}
