import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// GME-01 Games catalog list (no play host yet).
class GamesCatalogPage extends StatefulWidget {
  const GamesCatalogPage({
    super.key,
    required this.repository,
    this.independent = false,
    this.gradeLevel,
    this.junior = false,
  });

  final GameCatalogRepository repository;
  final bool independent;
  final int? gradeLevel;
  final bool junior;

  @override
  State<GamesCatalogPage> createState() => _GamesCatalogPageState();
}

class _GamesCatalogPageState extends State<GamesCatalogPage> {
  NanoViewState _state = const NanoViewLoading();
  GameCatalog? _catalog;

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
      if (!mounted) return;
      setState(() {
        _catalog = catalog;
        _state = const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          const NanoCopy(NanoAppLocale.en);
      setState(() => _state = NanoViewError(message: copy.gamesLoadError));
    }
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
                    copy.gamesComingSoonPlay,
                    style: theme.textTheme.bodyMedium,
                  ),
                  const SizedBox(height: NanoSpacing.md),
                  if (catalog.isEmpty)
                    Text(copy.gamesEmpty, style: theme.textTheme.bodyMedium)
                  else
                    for (final game in catalog.games)
                      Card(
                        margin: const EdgeInsets.only(bottom: NanoSpacing.sm),
                        child: ListTile(
                          title: Text(game.titleFor(urdu)),
                          subtitle: Text(
                            [
                              copy.gamesCategoryLabel(game.category.wire),
                              game.summaryFor(urdu),
                            ].join(' · '),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                          isThreeLine: true,
                        ),
                      ),
                ],
              ),
      ),
    );
  }
}
