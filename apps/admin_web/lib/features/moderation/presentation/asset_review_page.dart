import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

import 'media_element_view.dart';

/// MED-05 superadmin publication surface.
///
/// This is the only screen in Nano that can make generated media visible to a
/// learner. Everything MED-01 through MED-04 produced is sitting unreviewed
/// until somebody decides here, so the screen is built around one question --
/// "should a child see this?" -- and shows the reviewer what they need to
/// answer it: the file itself, what was asked for, and who asked.
class AssetReviewPage extends StatefulWidget {
  const AssetReviewPage({super.key, required this.repository});

  final AssetReviewRepository repository;

  @override
  State<AssetReviewPage> createState() => _AssetReviewPageState();
}

class _AssetReviewPageState extends State<AssetReviewPage> {
  NanoViewState _state = const NanoViewLoading();
  List<AssetReviewItem> _items = const [];
  List<AssetReviewEvent> _history = const [];
  AssetReviewItem? _selected;
  GeneratedAssetModeration? _filter = GeneratedAssetModeration.unreviewed;
  final _reason = TextEditingController();
  var _deciding = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final items = await widget.repository.queue(moderation: _filter);
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
                title: copy.assetReviewQueueEmptyTitle,
                message: copy.assetReviewQueueEmptyBody,
              )
            : const NanoViewReady();
      });
      await _loadHistory();
    } on AssetReviewRefused catch (error) {
      // A refusal here means the signed-in account is not a platform admin.
      // Showing the server's sentence is more use than a generic error.
      if (!mounted) return;
      setState(() => _state = NanoViewError(message: error.message));
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _loadHistory() async {
    final selected = _selected;
    if (selected == null) {
      setState(() => _history = const []);
      return;
    }
    try {
      final events = await widget.repository.history(selected.id);
      if (!mounted) return;
      setState(() => _history = events);
    } catch (_) {
      // History is context, not the decision. Losing it must not block a review.
      if (!mounted) return;
      setState(() => _history = const []);
    }
  }

  Future<void> _decide(GeneratedAssetModeration decision) async {
    final selected = _selected;
    if (selected == null) return;

    setState(() => _deciding = true);
    try {
      final outcome = await widget.repository.decide(
        [selected.id],
        decision,
        note: _reason.text,
      );
      if (!mounted) return;
      setState(() {
        _deciding = false;
        _reason.clear();
      });
      _say(_copy.assetReviewCount(outcome.reviewed, outcome.unchanged));
      await _load();
    } on AssetReviewRefused catch (error) {
      if (!mounted) return;
      setState(() => _deciding = false);
      _say(error.message);
    } catch (_) {
      if (!mounted) return;
      setState(() => _deciding = false);
      _say('Could not record that decision.');
    }
  }

  void _say(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  NanoCopy get _copy =>
      NanoLocaleScope.maybeOf(context)?.copy ?? NanoCopy(NanoAppLocale.en);

  @override
  Widget build(BuildContext context) {
    final copy = _copy;
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.md),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                copy.assetReviewTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: NanoSpacing.sm),
              _FilterBar(
                copy: copy,
                selected: _filter,
                onChanged: (value) {
                  setState(() => _filter = value);
                  _load();
                },
              ),
              const SizedBox(height: NanoSpacing.md),
              Expanded(
                child: NanoViewStateHost(
                  state: _state,
                  onRetry: _load,
                  child: SizedBox.expand(
                    child: NanoMaxContentWidth(
                      maxWidth: 1100,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Expanded(
                            flex: 4,
                            child: _QueueList(
                              copy: copy,
                              items: _items,
                              selected: _selected,
                              onSelect: (item) {
                                setState(() {
                                  _selected = item;
                                  _reason.clear();
                                });
                                _loadHistory();
                              },
                            ),
                          ),
                          const SizedBox(width: NanoSpacing.lg),
                          Expanded(
                            flex: 6,
                            child: _selected == null
                                ? const SizedBox.shrink()
                                : _ReviewDetail(
                                    item: _selected!,
                                    history: _history,
                                    copy: copy,
                                    reason: _reason,
                                    busy: _deciding,
                                    repository: widget.repository,
                                    onDecide: _decide,
                                  ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterBar extends StatelessWidget {
  const _FilterBar({
    required this.copy,
    required this.selected,
    required this.onChanged,
  });

  final NanoCopy copy;
  final GeneratedAssetModeration? selected;
  final ValueChanged<GeneratedAssetModeration?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: NanoSpacing.sm,
      children: [
        for (final state in GeneratedAssetModeration.values)
          ChoiceChip(
            label: Text(copy.assetModerationLabel(state)),
            selected: selected == state,
            onSelected: (_) => onChanged(selected == state ? null : state),
          ),
      ],
    );
  }
}

class _QueueList extends StatelessWidget {
  const _QueueList({
    required this.copy,
    required this.items,
    required this.selected,
    required this.onSelect,
  });

  final NanoCopy copy;
  final List<AssetReviewItem> items;
  final AssetReviewItem? selected;
  final ValueChanged<AssetReviewItem> onSelect;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: NanoSpacing.xs),
      itemBuilder: (context, index) {
        final item = items[index];
        return ListTile(
          selected: item.id == selected?.id,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(NanoRadii.senior),
          ),
          leading: Icon(_iconFor(item.kind)),
          title: Text(item.slot, maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
            '${copy.assetModerationLabel(item.moderation)} · '
            '${item.locale} · ${item.status.name}',
          ),
          // A stuck job is listed so it is visible, and marked so nobody wastes
          // a click trying to publish something that has no file.
          trailing: item.isDecidable
              ? null
              : const Icon(Icons.hourglass_empty, size: 18),
          onTap: () => onSelect(item),
        );
      },
    );
  }

  static IconData _iconFor(GeneratedAssetKind kind) => switch (kind) {
        GeneratedAssetKind.image => Icons.image_outlined,
        GeneratedAssetKind.voice => Icons.graphic_eq,
        GeneratedAssetKind.video => Icons.movie_outlined,
      };
}

class _ReviewDetail extends StatelessWidget {
  const _ReviewDetail({
    required this.item,
    required this.history,
    required this.copy,
    required this.reason,
    required this.busy,
    required this.repository,
    required this.onDecide,
  });

  final AssetReviewItem item;
  final List<AssetReviewEvent> history;
  final NanoCopy copy;
  final TextEditingController reason;
  final bool busy;
  final AssetReviewRepository repository;
  final ValueChanged<GeneratedAssetModeration> onDecide;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return ListView(
      children: [
        Text(item.slot, style: theme.textTheme.headlineSmall),
        const SizedBox(height: NanoSpacing.xs),
        Text(
          '${copy.assetModerationLabel(item.moderation)} · ${item.kind.name} · '
          '${item.locale} · ${item.aspectRatio}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: NanoSpacing.md),

        Text(copy.assetPreviewLabel, style: theme.textTheme.titleMedium),
        const SizedBox(height: NanoSpacing.xs),
        _Preview(item: item, copy: copy, repository: repository),

        const SizedBox(height: NanoSpacing.md),
        Text(copy.assetPromptLabel, style: theme.textTheme.titleMedium),
        // Provenance: a reviewer approves a prompt as much as a picture, because
        // the same prompt will be reused for every later ask that matches it.
        SelectableText(item.prompt, style: theme.textTheme.bodyMedium),
        const SizedBox(height: NanoSpacing.xs),
        Text(
          '${item.providerId} · ${item.promptVersion} · '
          '${item.feature} · ${_cost(item.costMicros)}',
          style: theme.textTheme.bodySmall,
        ),
        if (item.errorCode != null) ...[
          const SizedBox(height: NanoSpacing.xs),
          Text(item.errorCode!, style: theme.textTheme.bodySmall),
        ],

        const SizedBox(height: NanoSpacing.md),
        TextField(
          controller: reason,
          maxLines: 2,
          decoration: InputDecoration(
            labelText: copy.assetRejectReasonLabel,
            hintText: copy.assetRejectReasonHint,
          ),
        ),
        const SizedBox(height: NanoSpacing.sm),
        Wrap(
          spacing: NanoSpacing.sm,
          runSpacing: NanoSpacing.xs,
          children: [
            FilledButton.icon(
              // Disabled rather than hidden, with the reason spelled out below,
              // so a stuck job does not look like a missing feature.
              onPressed: busy || !item.isDecidable || item.isPublished
                  ? null
                  : () => onDecide(GeneratedAssetModeration.approved),
              icon: const Icon(Icons.check),
              label: Text(copy.assetApproveLabel),
            ),
            OutlinedButton.icon(
              onPressed: busy ||
                      item.moderation == GeneratedAssetModeration.rejected
                  ? null
                  : () => onDecide(GeneratedAssetModeration.rejected),
              icon: const Icon(Icons.block),
              label: Text(copy.assetRejectLabel),
            ),
            if (item.moderation != GeneratedAssetModeration.unreviewed)
              TextButton(
                onPressed: busy
                    ? null
                    : () => onDecide(GeneratedAssetModeration.unreviewed),
                child: Text(copy.assetReturnToQueueLabel),
              ),
          ],
        ),
        if (!item.isDecidable) ...[
          const SizedBox(height: NanoSpacing.xs),
          Text(copy.assetNotDecidable, style: theme.textTheme.bodySmall),
        ],

        if (history.isNotEmpty) ...[
          const SizedBox(height: NanoSpacing.lg),
          Text(copy.assetReviewHistoryLabel, style: theme.textTheme.titleMedium),
          const SizedBox(height: NanoSpacing.xs),
          for (final event in history)
            Padding(
              padding: const EdgeInsets.only(bottom: NanoSpacing.xs),
              child: Text(
                '${copy.assetModerationLabel(event.decision)} · '
                '${event.reviewerName ?? '—'}'
                '${event.note.isEmpty ? '' : ' · ${event.note}'}',
                style: theme.textTheme.bodySmall,
              ),
            ),
        ],
      ],
    );
  }

  static String _cost(int micros) =>
      micros == 0 ? 'no cost' : '${(micros / 1000000).toStringAsFixed(4)} USD';
}

/// The file, as far as a web reviewer can see it.
///
/// Images render, and in a browser so do voice and video: admin_web is the one
/// app that only ever runs on the web, so it can hand an MP3 or an MP4 straight
/// to the element that already knows how to play it. Asking somebody to decide
/// whether a child should see a clip, while showing them a checksum, was not a
/// review.
///
/// Anywhere without a DOM — the widget tests — falls back to describing the
/// file, because a reviewer who cannot play it can still reject it, and
/// rejecting is the safe direction.
class _Preview extends StatelessWidget {
  const _Preview({
    required this.item,
    required this.copy,
    required this.repository,
  });

  final AssetReviewItem item;
  final NanoCopy copy;
  final AssetReviewRepository repository;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    if (!item.hasFile) {
      return Text(copy.assetPreviewUnavailable, style: theme.textTheme.bodyMedium);
    }

    return FutureBuilder<String>(
      // Keyed on the asset so switching selection refetches rather than showing
      // the previous asset's URL.
      key: ValueKey('preview-${item.id}'),
      future: repository.previewUrl(item),
      builder: (context, snapshot) {
        if (snapshot.connectionState != ConnectionState.done) {
          return const SizedBox(
            height: 120,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        if (snapshot.hasError || snapshot.data == null) {
          // A preview that will not load must not stop the queue: the reviewer
          // can still reject, which is the safe direction.
          return Text(
            copy.assetPreviewUnavailable,
            style: theme.textTheme.bodyMedium,
          );
        }

        final url = snapshot.data!;
        if (item.kind == GeneratedAssetKind.image) {
          return ConstrainedBox(
            constraints: const BoxConstraints(maxHeight: 320),
            child: Image.network(
              url,
              fit: BoxFit.contain,
              errorBuilder: (context, _, _) => Text(
                copy.assetPreviewUnavailable,
                style: theme.textTheme.bodyMedium,
              ),
            ),
          );
        }

        final isVideo = item.kind == GeneratedAssetKind.video;
        final player = mediaElementView(url: url, isVideo: isVideo);

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (player != null) ...[
              SizedBox(
                // A clip gets room to be looked at; a waveform-less audio bar
                // needs only its own height.
                height: isVideo ? 280 : 54,
                width: double.infinity,
                child: player,
              ),
              const SizedBox(height: NanoSpacing.sm),
            ],
            Text(
              '${item.contentType ?? item.kind.name} · '
              '${_size(item.byteSize)}',
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: NanoSpacing.xs),
            SelectableText(
              item.checksum ?? '',
              style: theme.textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  static String _size(int? bytes) =>
      bytes == null ? '—' : '${(bytes / 1024).round()} KB';
}
