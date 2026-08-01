import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// ADM-04 Catalog tab: draft, publish, and archive subjects/topics.
class LearningCatalogAdminPage extends StatefulWidget {
  const LearningCatalogAdminPage({
    super.key,
    required this.repository,
  });

  final LearningContentRepository repository;

  @override
  State<LearningCatalogAdminPage> createState() =>
      _LearningCatalogAdminPageState();
}

class _LearningCatalogAdminPageState extends State<LearningCatalogAdminPage> {
  NanoViewState _state = const NanoViewLoading();
  List<AuthoringSubject> _subjects = const [];
  AuthoringSubject? _selected;
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
      final subjects =
          await widget.repository.listSubjects(query: _search.text);
      if (!mounted) return;
      setState(() {
        _subjects = subjects;
        _selected = subjects.isEmpty
            ? null
            : subjects.firstWhere(
                (item) => item.subjectId == _selected?.subjectId,
                orElse: () => subjects.first,
              );
        _state = subjects.isEmpty
            ? const NanoViewEmpty(
                title: 'No subjects yet',
                message: 'Create a draft subject to start the catalog.',
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

  Future<void> _createSubject() async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _run(() async {
      final created = await widget.repository.createSubjectDraft(
        slug: 'subject-$stamp',
        title: 'New subject $stamp',
        summary: 'Draft subject awaiting media and topics.',
        track: 'both',
      );
      _selected = created;
    });
  }

  Future<void> _createTopic(AuthoringSubject subject) async {
    final stamp = DateTime.now().millisecondsSinceEpoch;
    await _run(() async {
      await widget.repository.createTopicDraft(
        subjectId: subject.subjectId,
        slug: 'topic-$stamp',
        title: 'New topic $stamp',
        objectives: const ['Learn the core idea'],
        estimatedMinutes: 12,
        durationSeconds: 120,
        videoProvider: 'fixture',
        videoRef: 'fixture://draft-$stamp',
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
                        hintText: copy.authoringSearchHint,
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
                        onPressed: _busy ? null : _createSubject,
                        icon: const Icon(Icons.add),
                        label: Text(copy.authoringNewSubject),
                      ),
                    ),
                  ),
                  const SizedBox(height: NanoSpacing.sm),
                  Expanded(
                    child: ListView.builder(
                      itemCount: _subjects.length,
                      itemBuilder: (context, index) {
                        final subject = _subjects[index];
                        return ListTile(
                          selected: subject.subjectId == selected?.subjectId,
                          title: Text(subject.title),
                          subtitle: Text(
                            '${subject.slug} · ${subject.status.wireName}',
                          ),
                          onTap: () => setState(() => _selected = subject),
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
                  ? Center(child: Text(copy.authoringEmptyDetail))
                  : ListView(
                      padding: const EdgeInsets.all(NanoSpacing.md),
                      children: [
                        Text(
                          selected.title,
                          style: theme.textTheme.headlineSmall,
                        ),
                        const SizedBox(height: NanoSpacing.xs),
                        Text(
                          '${selected.slug} · ${selected.status.wireName} · '
                          'v${selected.version} · ${selected.track}',
                        ),
                        const SizedBox(height: NanoSpacing.xs),
                        Text(selected.summary),
                        const SizedBox(height: NanoSpacing.sm),
                        Text(
                          '${copy.authoringVersionId}: ${selected.subjectVersionId}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: NanoSpacing.md),
                        Wrap(
                          spacing: NanoSpacing.sm,
                          runSpacing: NanoSpacing.sm,
                          children: [
                            if (selected.isDraft)
                              FilledButton(
                                onPressed: _busy
                                    ? null
                                    : () => _run(
                                          () async {
                                            await widget.repository
                                                .publishSubject(
                                              selected.subjectVersionId,
                                            );
                                          },
                                        ),
                                child: Text(copy.authoringPublishSubject),
                              ),
                            if (selected.isPublished)
                              OutlinedButton(
                                onPressed: _busy
                                    ? null
                                    : () => _run(
                                          () async {
                                            await widget.repository
                                                .archiveSubject(
                                              selected.subjectVersionId,
                                            );
                                          },
                                        ),
                                child: Text(copy.authoringArchiveSubject),
                              ),
                            OutlinedButton(
                              onPressed:
                                  _busy ? null : () => _createTopic(selected),
                              child: Text(copy.authoringNewTopic),
                            ),
                          ],
                        ),
                        const SizedBox(height: NanoSpacing.lg),
                        Text(
                          copy.authoringTopicsTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: NanoSpacing.sm),
                        if (selected.topics.isEmpty)
                          Text(copy.authoringNoTopics)
                        else
                          for (final topic in selected.topics)
                            Card(
                              margin:
                                  const EdgeInsets.only(bottom: NanoSpacing.sm),
                              child: ListTile(
                                title: Text(
                                  '${topic.title} · ${topic.status.wireName}',
                                ),
                                subtitle: Text(
                                  [
                                    topic.slug,
                                    '${topic.estimatedMinutes} min',
                                    if (topic.videoProvider != null)
                                      topic.videoProvider!,
                                    '${copy.authoringVersionId}: ${topic.topicVersionId}',
                                  ].join(' · '),
                                ),
                                isThreeLine: true,
                                trailing: Wrap(
                                  spacing: NanoSpacing.xs,
                                  children: [
                                    if (topic.isDraft)
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _run(
                                                  () async {
                                                    await widget.repository
                                                        .publishTopic(
                                                      topic.topicVersionId,
                                                    );
                                                  },
                                                ),
                                        child: Text(copy.authoringPublishTopic),
                                      ),
                                    if (topic.isPublished)
                                      TextButton(
                                        onPressed: _busy
                                            ? null
                                            : () => _run(
                                                  () async {
                                                    await widget.repository
                                                        .archiveTopic(
                                                      topic.topicVersionId,
                                                    );
                                                  },
                                                ),
                                        child: Text(copy.authoringArchiveTopic),
                                      ),
                                  ],
                                ),
                              ),
                            ),
                        const SizedBox(height: NanoSpacing.lg),
                        Text(
                          copy.authoringPreviewTitle,
                          style: theme.textTheme.titleMedium,
                        ),
                        const SizedBox(height: NanoSpacing.xs),
                        Text(
                          '${copy.authoringJuniorPreview}: ${selected.title}'
                          '${selected.titleUr == null ? '' : ' / ${selected.titleUr}'}',
                        ),
                        Text(
                          '${copy.authoringSeniorPreview}: ${selected.title}'
                          '${selected.titleUr == null ? '' : ' / ${selected.titleUr}'}',
                        ),
                        Text(
                          '${copy.authoringSharedVersion}: ${selected.subjectVersionId}',
                          style: theme.textTheme.bodySmall,
                        ),
                      ],
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
