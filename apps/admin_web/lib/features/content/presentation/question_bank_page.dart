import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// QZ-01 curator screen: browse, draft, publish, and preview questions.
///
/// Correct answers are visible here because this is a platform-admin surface.
/// Learners never read these rows; QZ-02 attaches published versions to quizzes.
class QuestionBankPage extends StatefulWidget {
  const QuestionBankPage({
    super.key,
    required this.repository,
  });

  final QuestionBankRepository repository;

  @override
  State<QuestionBankPage> createState() => _QuestionBankPageState();
}

class _QuestionBankPageState extends State<QuestionBankPage> {
  NanoViewState _state = const NanoViewLoading();
  List<QuestionVersion> _items = const [];
  QuestionVersion? _selected;
  final _search = TextEditingController();
  var _creating = false;

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
      final items = await widget.repository.listQuestions(query: _search.text);
      if (!mounted) return;
      setState(() {
        _items = items;
        _selected = items.isEmpty
            ? null
            : items.firstWhere(
                (item) => item.id == _selected?.id,
                orElse: () => items.first,
              );
        _state = items.isEmpty
            ? const NanoViewEmpty(
                title: 'No questions yet',
                message: 'Create a draft to start the bank.',
              )
            : const NanoViewReady();
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  Future<void> _createDraft() async {
    setState(() => _creating = true);
    try {
      final created = await widget.repository.createDraft(
        slug: 'draft-${DateTime.now().millisecondsSinceEpoch}',
        stem: 'Which number comes after 4?',
        stemUr: '4 کے بعد کون سا نمبر آتا ہے؟',
        options: const [
          QuestionOption(id: 'a', label: '3', labelUr: '3'),
          QuestionOption(id: 'b', label: '5', labelUr: '5', isCorrect: true),
          QuestionOption(id: 'c', label: '6', labelUr: '6'),
        ],
        explanation: 'After four comes five.',
        explanationUr: 'چار کے بعد پانچ آتا ہے۔',
        provenance: 'manual draft',
      );
      if (!mounted) return;
      setState(() {
        _creating = false;
        _selected = created;
      });
      if (created.hasDuplicates) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              NanoLocaleScope.maybeOf(context)?.copy.duplicateWarning ??
                  'A similar question already exists.',
            ),
          ),
        );
      }
      await _load();
      setState(() => _selected = created);
    } catch (_) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create draft')),
      );
    }
  }

  Future<void> _publish(QuestionVersion question) async {
    try {
      final published = await widget.repository.publish(question.id);
      if (!mounted) return;
      setState(() => _selected = published);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not publish')),
      );
    }
  }

  Future<void> _retire(QuestionVersion question) async {
    try {
      final retired = await widget.repository.retire(question.id);
      if (!mounted) return;
      setState(() => _selected = retired);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not retire')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(NanoSpacing.md),
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
                      child: _BankList(
                        copy: copy,
                        items: _items,
                        selected: _selected,
                        search: _search,
                        creating: _creating,
                        onSearch: (_) => _load(),
                        onSelect: (item) => setState(() => _selected = item),
                        onCreate: _createDraft,
                      ),
                    ),
                    const SizedBox(width: NanoSpacing.lg),
                    Expanded(
                      flex: 6,
                      child: _selected == null
                          ? const SizedBox.shrink()
                          : _QuestionDetail(
                              question: _selected!,
                              copy: copy,
                              onPublish: () => _publish(_selected!),
                              onRetire: () => _retire(_selected!),
                            ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BankList extends StatelessWidget {
  const _BankList({
    required this.copy,
    required this.items,
    required this.selected,
    required this.search,
    required this.creating,
    required this.onSearch,
    required this.onSelect,
    required this.onCreate,
  });

  final NanoCopy copy;
  final List<QuestionVersion> items;
  final QuestionVersion? selected;
  final TextEditingController search;
  final bool creating;
  final ValueChanged<String> onSearch;
  final ValueChanged<QuestionVersion> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale =
        NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.questionBankTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: NanoSpacing.sm),
        TextField(
          controller: search,
          onChanged: onSearch,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search stem or slug',
          ),
        ),
        const SizedBox(height: NanoSpacing.sm),
        FilledButton.icon(
          onPressed: creating ? null : onCreate,
          icon: const Icon(Icons.add),
          label: Text(copy.newQuestionLabel),
        ),
        const SizedBox(height: NanoSpacing.md),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: NanoSpacing.xs),
            itemBuilder: (context, index) {
              final item = items[index];
              final selectedHere = item.id == selected?.id;
              return ListTile(
                selected: selectedHere,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NanoRadii.senior),
                ),
                title: Text(
                  item.stemFor(locale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Text(
                  '${copy.questionStatusLabel(item.status.wireName)} · '
                  '${item.difficulty.wireName} · v${item.version}',
                ),
                onTap: () => onSelect(item),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuestionDetail extends StatelessWidget {
  const _QuestionDetail({
    required this.question,
    required this.copy,
    required this.onPublish,
    required this.onRetire,
  });

  final QuestionVersion question;
  final NanoCopy copy;
  final VoidCallback onPublish;
  final VoidCallback onRetire;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final locale =
        NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    return ListView(
      children: [
        Text(question.stemFor(locale), style: theme.textTheme.headlineSmall),
        const SizedBox(height: NanoSpacing.xs),
        Text(
          '${copy.questionStatusLabel(question.status.wireName)} · '
          '${question.kind.wireName} · ${question.difficulty.wireName}',
          style: theme.textTheme.bodyMedium,
        ),
        const SizedBox(height: NanoSpacing.xs),
        SelectableText(
          '${copy.versionIdLabel}: ${question.id}',
          style: theme.textTheme.bodySmall,
        ),
        if (question.provenance.isNotEmpty) ...[
          const SizedBox(height: NanoSpacing.xs),
          Text(
            '${copy.provenanceLabel}: ${question.provenance}',
            style: theme.textTheme.bodySmall,
          ),
        ],
        if (question.hasDuplicates) ...[
          const SizedBox(height: NanoSpacing.sm),
          Text(copy.duplicateWarning, style: theme.textTheme.titleSmall),
          for (final dup in question.duplicates)
            Text('• ${dup.slug} (v${dup.version})'),
        ],
        const SizedBox(height: NanoSpacing.md),
        Wrap(
          spacing: NanoSpacing.sm,
          children: [
            if (question.status.isEditable)
              FilledButton(
                onPressed: onPublish,
                child: Text(copy.publishQuestionLabel),
              ),
            if (question.status == QuestionStatus.published)
              OutlinedButton(
                onPressed: onRetire,
                child: Text(copy.retireQuestionLabel),
              ),
          ],
        ),
        const SizedBox(height: NanoSpacing.lg),
        Text(copy.juniorPreviewLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        _PreviewCard(question: question, junior: true),
        const SizedBox(height: NanoSpacing.lg),
        Text(copy.seniorPreviewLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        _PreviewCard(question: question, junior: false),
        const SizedBox(height: NanoSpacing.lg),
        Text(copy.correctOptionLabel, style: theme.textTheme.titleMedium),
        Text(question.correctOption?.labelFor(locale) ?? '—'),
        if (question.explanation.isNotEmpty) ...[
          const SizedBox(height: NanoSpacing.sm),
          Text(copy.explanationLabel, style: theme.textTheme.titleMedium),
          Text(question.explanationFor(locale)),
        ],
      ],
    );
  }
}

class _PreviewCard extends StatelessWidget {
  const _PreviewCard({required this.question, required this.junior});

  final QuestionVersion question;
  final bool junior;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale =
        NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final theme = Theme.of(context);
    return Card(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(
          junior ? NanoRadii.junior : NanoRadii.senior,
        ),
      ),
      child: Padding(
        padding: EdgeInsets.all(
          junior ? NanoSpacing.cardPaddingJunior : NanoSpacing.cardPaddingSenior,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (junior) ...[
              const CompanionSlot(size: 64),
              const SizedBox(height: NanoSpacing.sm),
            ],
            Text(
              question.stemFor(locale),
              style: junior
                  ? theme.textTheme.headlineSmall
                  : theme.textTheme.titleLarge,
            ),
            const SizedBox(height: NanoSpacing.sm),
            for (final option in question.options)
              Padding(
                padding: const EdgeInsets.only(bottom: NanoSpacing.xs),
                child: junior
                    ? FilledButton.tonal(
                        onPressed: () {},
                        child: Align(
                          alignment: Alignment.centerLeft,
                          child: Text(option.labelFor(locale)),
                        ),
                      )
                    : ListTile(
                        contentPadding: EdgeInsets.zero,
                        title: Text(option.labelFor(locale)),
                        leading: const Icon(Icons.radio_button_unchecked),
                      ),
              ),
            Text(
              '${copy.versionIdLabel}: ${question.id}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
