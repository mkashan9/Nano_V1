import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ADM-06 Games hub: draft, publish, and disable catalog versions.
class GameAdminPage extends StatefulWidget {
  const GameAdminPage({
    super.key,
    required this.repository,
  });

  final GameAdminRepository repository;

  @override
  State<GameAdminPage> createState() => _GameAdminPageState();
}

class _GameAdminPageState extends State<GameAdminPage> {
  NanoViewState _state = const NanoViewLoading();
  List<AdminGame> _games = const [];
  AdminGame? _selected;
  final _search = TextEditingController();
  var _busy = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final games = await widget.repository.listGames(query: _search.text);
      if (!mounted) return;
      setState(() {
        _games = games;
        _selected = games.isEmpty
            ? null
            : games.firstWhere(
                (item) => item.gameId == _selected?.gameId,
                orElse: () => games.first,
              );
        _state = games.isEmpty
            ? const NanoViewEmpty(
                title: 'No games yet',
                message: 'Create a draft game to start the catalog.',
              )
            : const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _run(Future<void> Function() action) async {
    setState(() => _busy = true);
    try {
      await action();
      await _load();
    } catch (error) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('$error')),
      );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _createGame() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _run(() async {
      final created = await widget.repository.createDraft(
        slug: 'game_$stamp',
        titleEn: 'New game $stamp',
        summaryEn: 'Draft game awaiting host wiring.',
        entryRef: 'fixture://draft-$stamp',
      );
      _selected = created;
    });
  }

  Future<void> _disable(AdminGame game) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) {
        final copy = NanoLocaleScope.maybeOf(context)?.copy ??
            const NanoCopy(NanoAppLocale.en);
        return AlertDialog(
          title: Text(copy.gameAdminDisable),
          content: TextField(
            controller: reasonController,
            decoration: InputDecoration(labelText: copy.gameAdminReason),
            autofocus: true,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(copy.cancelLabel),
            ),
            FilledButton(
              onPressed: () =>
                  Navigator.pop(context, reasonController.text),
              child: Text(copy.gameAdminDisable),
            ),
          ],
        );
      },
    );
    reasonController.dispose();
    if (reason == null) return;
    await _run(() async {
      await widget.repository.disable(
        gameVersionId: game.gameVersionId,
        reason: reason,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        const NanoCopy(NanoAppLocale.en);
    final theme = Theme.of(context);
    final selected = _selected;

    return Scaffold(
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: Row(
          children: [
            SizedBox(
              width: 320,
              child: Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(NanoSpacing.sm),
                    child: TextField(
                      controller: _search,
                      decoration: InputDecoration(
                        hintText: copy.gameAdminSearchHint,
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: IconButton(
                          onPressed: _busy ? null : _load,
                          icon: const Icon(Icons.refresh),
                        ),
                      ),
                      onSubmitted: (_) => _load(),
                    ),
                  ),
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: NanoSpacing.sm),
                    child: Align(
                      alignment: Alignment.centerLeft,
                      child: FilledButton.icon(
                        onPressed: _busy ? null : _createGame,
                        icon: const Icon(Icons.add),
                        label: Text(copy.gameAdminNew),
                      ),
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _games.length,
                      itemBuilder: (context, index) {
                        final game = _games[index];
                        final selectedId = selected?.gameId;
                        return ListTile(
                          selected: game.gameId == selectedId,
                          title: Text(game.titleEn),
                          subtitle: Text(
                            '${game.slug} · ${game.status.wireName}'
                            '${game.enabled ? '' : ' · off'}',
                          ),
                          onTap: () => setState(() => _selected = game),
                        );
                      },
                    ),
                  ),
                ],
              ),
            ),
            const VerticalDivider(width: 1),
            Expanded(
              child: selected == null
                  ? Center(child: Text(copy.gameAdminEmptyDetail))
                  : Padding(
                      padding: const EdgeInsets.all(NanoSpacing.md),
                      child: ListView(
                        children: [
                          Text(
                            selected.titleEn,
                            style: theme.textTheme.headlineSmall,
                          ),
                          const SizedBox(height: NanoSpacing.xs),
                          Text(
                            '${selected.slug} · v${selected.version} · '
                            '${selected.category}',
                          ),
                          if (selected.summaryEn.isNotEmpty) ...[
                            const SizedBox(height: NanoSpacing.sm),
                            Text(selected.summaryEn),
                          ],
                          const SizedBox(height: NanoSpacing.sm),
                          Text(
                            '${copy.gameAdminStatus}: ${selected.status.wireName}'
                            '${selected.enabled ? '' : ' (disabled)'}',
                          ),
                          Text(
                            '${copy.gameAdminEntry}: '
                            '${selected.entryKind} · ${selected.entryRef}',
                          ),
                          const SizedBox(height: NanoSpacing.md),
                          Wrap(
                            spacing: NanoSpacing.sm,
                            runSpacing: NanoSpacing.sm,
                            children: [
                              if (selected.isDraft)
                                FilledButton(
                                  onPressed: _busy ||
                                          !GamePublishPolicy.ready(selected)
                                      ? null
                                      : () => _run(() async {
                                            await widget.repository.publish(
                                              selected.gameVersionId,
                                            );
                                          }),
                                  child: Text(copy.gameAdminPublish),
                                ),
                              if (selected.enabled)
                                OutlinedButton(
                                  onPressed:
                                      _busy ? null : () => _disable(selected),
                                  child: Text(copy.gameAdminDisable),
                                ),
                            ],
                          ),
                        ],
                      ),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
