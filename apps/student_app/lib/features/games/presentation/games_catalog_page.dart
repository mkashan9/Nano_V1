import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/games/presentation/game_host_page.dart';

/// GME-01..04 Games catalog with Play + local save/update/free-space.
class GamesCatalogPage extends StatefulWidget {
  const GamesCatalogPage({
    super.key,
    required this.repository,
    this.sessionRepository,
    this.assetRepository,
    this.localStorageRepository,
    this.accessibility = AccessibilityPreferences.defaults,
    this.onAccessibilityChanged,
    this.independent = false,
    this.gradeLevel,
    this.junior = false,
  });

  final GameCatalogRepository repository;
  final GameSessionRepository? sessionRepository;
  final GameAssetRepository? assetRepository;
  final GameLocalStorageRepository? localStorageRepository;
  final AccessibilityPreferences accessibility;
  final ValueChanged<AccessibilityPreferences>? onAccessibilityChanged;
  final bool independent;
  final int? gradeLevel;
  final bool junior;

  @override
  State<GamesCatalogPage> createState() => _GamesCatalogPageState();
}

class _GamesCatalogPageState extends State<GamesCatalogPage> {
  NanoViewState _state = const NanoViewLoading();
  GameCatalog? _catalog;
  final Map<String, GameAssetManifest> _manifests = {};
  final Map<String, GameLocalInstallStatus> _statuses = {};
  var _storageBytes = 0;

  GameAssetRepository get _assets =>
      widget.assetRepository ?? FakeGameAssetRepository();
  GameLocalStorageRepository get _local =>
      widget.localStorageRepository ?? FakeGameLocalStorageRepository();

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final catalog = await widget.repository.loadCatalog(
        independent: widget.independent,
        gradeLevel: widget.gradeLevel,
      );
      final manifests = <String, GameAssetManifest>{};
      final statuses = <String, GameLocalInstallStatus>{};
      for (final game in catalog.games) {
        final manifest = await _assets.loadAssets(game.versionId);
        final local = await _local.getInstall(game.versionId);
        manifests[game.versionId] = manifest;
        statuses[game.versionId] = GameInstallStateResolver.resolve(
          remote: manifest,
          local: local,
        );
      }
      final used = await _local.totalBytesUsed();
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _manifests
          ..clear()
          ..addAll(manifests);
        _statuses
          ..clear()
          ..addAll(statuses);
        _storageBytes = used;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() => _state = NanoViewError(message: copy.gamesLoadError));
    }
  }

  Future<void> _save(CatalogGame game) async {
    final manifest = _manifests[game.versionId] ??
        await _assets.loadAssets(game.versionId);
    try {
      await _local.install(manifest: manifest);
      final used = await _local.totalBytesUsed();
      if (!mounted) return;
      setState(() {
        _manifests[game.versionId] = manifest;
        _statuses[game.versionId] = GameLocalInstallStatus.ready;
        _storageBytes = used;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _statuses[game.versionId] = GameLocalInstallStatus.failed);
    }
  }

  Future<void> _free(CatalogGame game) async {
    await _local.remove(game.versionId);
    final used = await _local.totalBytesUsed();
    if (!mounted) return;
    setState(() {
      _statuses[game.versionId] = GameLocalInstallStatus.notOnDevice;
      _storageBytes = used;
    });
  }

  void _open(CatalogGame game) {
    final sessions = widget.sessionRepository ?? FakeGameSessionRepository();
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => GameHostPage(
          game: game,
          sessionRepository: sessions,
          accessibility: widget.accessibility,
          onAccessibilityChanged: widget.onAccessibilityChanged,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final urdu = copy.isUrdu;
    final catalog = _catalog;

    return NanoScaffold(
      padBody: true,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: catalog == null
            ? const SizedBox.shrink()
            : ListView(
                children: [
                  Text(copy.games, style: theme.textTheme.headlineSmall),
                  const SizedBox(height: NanoSpacing.xs),
                  Text(
                    copy.gamesHostIntro,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: NanoSpacing.xs),
                  Text(
                    copy.gamesStorageUsed(_storageBytes),
                    style: theme.textTheme.bodySmall,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  if (catalog.isEmpty)
                    Text(copy.gamesEmpty, style: theme.textTheme.bodyMedium)
                  else
                    for (final game in catalog.games)
                      _GameStorageTile(
                        game: game,
                        urdu: urdu,
                        copy: copy,
                        status: _statuses[game.versionId] ??
                            GameLocalInstallStatus.notOnDevice,
                        onPlay: () => _open(game),
                        onSave: () => _save(game),
                        onFree: () => _free(game),
                      ),
                ],
              ),
      ),
    );
  }
}

class _GameStorageTile extends StatelessWidget {
  const _GameStorageTile({
    required this.game,
    required this.urdu,
    required this.copy,
    required this.status,
    required this.onPlay,
    required this.onSave,
    required this.onFree,
  });

  final CatalogGame game;
  final bool urdu;
  final NanoCopy copy;
  final GameLocalInstallStatus status;
  final VoidCallback onPlay;
  final VoidCallback onSave;
  final VoidCallback onFree;

  @override
  Widget build(BuildContext context) {
    final playable = game.entryKind == GameEntryKind.web ||
        game.entryKind == GameEntryKind.flutter;
    final canPlay = playable &&
        (status == GameLocalInstallStatus.ready ||
            status == GameLocalInstallStatus.updateAvailable);
    return Card(
      margin: const EdgeInsets.only(bottom: NanoSpacing.sm),
      child: Padding(
        padding: const EdgeInsets.all(NanoSpacing.sm),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(game.titleFor(urdu),
                style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 4),
            Text(
              [
                copy.gamesCategoryLabel(game.category.wire),
                copy.gamesInstallStatusLabel(status),
                game.summaryFor(urdu),
              ].join(' · '),
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              children: [
                if (canPlay)
                  FilledButton(
                    onPressed: onPlay,
                    child: Text(copy.gamesPlay),
                  ),
                if (status == GameLocalInstallStatus.notOnDevice ||
                    status == GameLocalInstallStatus.failed)
                  OutlinedButton(
                    onPressed: onSave,
                    child: Text(copy.gamesSave),
                  ),
                if (status == GameLocalInstallStatus.updateAvailable)
                  OutlinedButton(
                    onPressed: onSave,
                    child: Text(copy.gamesUpdate),
                  ),
                if (status == GameLocalInstallStatus.ready ||
                    status == GameLocalInstallStatus.updateAvailable)
                  TextButton(
                    onPressed: onFree,
                    child: Text(copy.gamesFreeSpace),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
