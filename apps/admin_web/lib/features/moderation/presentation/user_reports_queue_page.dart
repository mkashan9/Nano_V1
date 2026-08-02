import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// SAFE-02: open learner reports with evidence + resolve actions.
class UserReportsQueuePage extends StatefulWidget {
  const UserReportsQueuePage({super.key, required this.repository});

  final ModerationQueueRepository repository;

  @override
  State<UserReportsQueuePage> createState() => _UserReportsQueuePageState();
}

class _UserReportsQueuePageState extends State<UserReportsQueuePage> {
  NanoViewState _state = const NanoViewLoading();
  List<ModerationQueueItem> _items = const [];
  ModerationQueueItem? _selected;
  final _note = TextEditingController();
  var _busy = false;

  NanoCopy get _copy =>
      NanoLocaleScope.maybeOf(context)?.copy ??
      const NanoCopy(NanoAppLocale.en);

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final items = await widget.repository.queue();
      if (!mounted) return;
      final copy = _copy;
      setState(() {
        _items = items;
        _selected = items.isEmpty
            ? null
            : items.firstWhere(
                (item) => item.id == _selected?.id,
                orElse: () => items.first,
              );
        _state = items.isEmpty
            ? NanoViewEmpty(
                title: copy.reportsQueueEmptyTitle,
                message: copy.reportsQueueEmptyBody,
              )
            : const NanoViewReady();
      });
    } on ModerationQueueRefused catch (error) {
      if (!mounted) return;
      setState(() => _state = NanoViewError(message: error.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _select(ModerationQueueItem item) async {
    setState(() {
      _selected = item;
      _busy = true;
    });
    try {
      final claimed = await widget.repository.claim(item.id);
      if (!mounted) return;
      setState(() {
        _selected = claimed;
        _busy = false;
        final index = _items.indexWhere((row) => row.id == claimed.id);
        if (index >= 0) {
          _items = [..._items]..[index] = claimed;
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
    }
  }

  Future<void> _resolve(ModerationResolution action) async {
    final selected = _selected;
    final note = _note.text.trim();
    if (selected == null || note.isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await widget.repository.resolve(selected.id, action, note: note);
      if (!mounted) return;
      _note.clear();
      setState(() => _busy = false);
      await _load();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_copy.reportResolvedLabel)),
      );
    } on ModerationQueueRefused catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _state = NanoViewError(message: error.message);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not resolve report')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    final theme = Theme.of(context);
    final selected = _selected;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(copy.reportsQueueTitle, style: theme.textTheme.headlineSmall),
              const SizedBox(height: NanoSpacing.sm),
              Text(copy.reportsQueueSubtitle, style: theme.textTheme.bodyMedium),
              const SizedBox(height: NanoSpacing.md),
              Expanded(
                child: switch (_state) {
                  NanoViewLoading() =>
                    const Center(child: CircularProgressIndicator()),
                  NanoViewError(:final message) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(message),
                          TextButton(
                            onPressed: _load,
                            child: Text(copy.retryLabel),
                          ),
                        ],
                      ),
                    ),
                  NanoViewEmpty(:final title, :final message) => Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(title, style: theme.textTheme.titleMedium),
                          const SizedBox(height: NanoSpacing.sm),
                          Text(message),
                        ],
                      ),
                    ),
                  _ => Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        SizedBox(
                          width: 320,
                          child: ListView.builder(
                            itemCount: _items.length,
                            itemBuilder: (context, index) {
                              final item = _items[index];
                              final active = item.id == selected?.id;
                              return ListTile(
                                selected: active,
                                title: Text(item.peerLabel),
                                subtitle: Text(
                                  [
                                    copy.reportCategoryLabel(item.category),
                                    item.status.name,
                                  ].join(' · '),
                                ),
                                onTap: _busy ? null : () => _select(item),
                              );
                            },
                          ),
                        ),
                        const VerticalDivider(width: 1),
                        Expanded(
                          child: selected == null
                              ? Center(child: Text(copy.reportsQueuePickHint))
                              : SingleChildScrollView(
                                  padding:
                                      const EdgeInsets.all(NanoSpacing.md),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.stretch,
                                    children: [
                                      Text(
                                        selected.peerLabel,
                                        style: theme.textTheme.titleLarge,
                                      ),
                                      if (selected.username != null)
                                        Text('@${selected.username}'),
                                      const SizedBox(height: NanoSpacing.sm),
                                      Text(
                                        copy.reportReportedBy(
                                          selected.reporterLabel,
                                        ),
                                      ),
                                      Text(
                                        copy.reportCategoryLabel(
                                          selected.category,
                                        ),
                                      ),
                                      if (selected.details != null) ...[
                                        const SizedBox(height: NanoSpacing.sm),
                                        Text(selected.details!),
                                      ],
                                      if (selected.alsoBlocked)
                                        Text(copy.reportAlsoBlockedHint),
                                      const SizedBox(height: NanoSpacing.md),
                                      Text(
                                        copy.reportEvidenceTitle,
                                        style: theme.textTheme.titleMedium,
                                      ),
                                      Text(
                                        selected.evidence.entries
                                            .map((e) => '${e.key}: ${e.value}')
                                            .join('\n'),
                                      ),
                                      const SizedBox(height: NanoSpacing.md),
                                      TextField(
                                        controller: _note,
                                        maxLines: 3,
                                        maxLength: 1000,
                                        enabled: !_busy,
                                        decoration: InputDecoration(
                                          labelText:
                                              copy.reportResolutionNoteHint,
                                        ),
                                      ),
                                      const SizedBox(height: NanoSpacing.sm),
                                      Wrap(
                                        spacing: NanoSpacing.sm,
                                        runSpacing: NanoSpacing.sm,
                                        children: [
                                          OutlinedButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _resolve(
                                                      ModerationResolution
                                                          .dismiss,
                                                    ),
                                            child:
                                                Text(copy.reportDismissLabel),
                                          ),
                                          OutlinedButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _resolve(
                                                      ModerationResolution
                                                          .resolve,
                                                    ),
                                            child:
                                                Text(copy.reportResolveLabel),
                                          ),
                                          OutlinedButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _resolve(
                                                      ModerationResolution.warn,
                                                    ),
                                            child: Text(copy.reportWarnLabel),
                                          ),
                                          FilledButton(
                                            onPressed: _busy
                                                ? null
                                                : () => _resolve(
                                                      ModerationResolution
                                                          .suspend,
                                                    ),
                                            child:
                                                Text(copy.reportSuspendLabel),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                        ),
                      ],
                    ),
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
