import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// QZ-02 curator screen: quizzes attached to topic versions, ordered items,
/// publish/retire, and Junior/Senior preview of the same version id.
class TopicQuizPage extends StatefulWidget {
  const TopicQuizPage({
    super.key,
    required this.repository,
    this.questionBank,
  });

  final TopicQuizRepository repository;
  final QuestionBankRepository? questionBank;

  @override
  State<TopicQuizPage> createState() => _TopicQuizPageState();
}

class _TopicQuizPageState extends State<TopicQuizPage> {
  NanoViewState _state = const NanoViewLoading();
  List<TopicQuiz> _items = const [];
  TopicQuiz? _selected;
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
      final items = await widget.repository.listQuizzes(query: _search.text);
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
                title: 'No topic quizzes yet',
                message: 'Attach questions from the bank to a topic.',
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
      final bank = widget.questionBank ?? FakeQuestionBankRepository();
      final questions = await bank.listQuestions();
      final published = questions
          .where((q) => q.status == QuestionStatus.published)
          .toList();
      if (published.isEmpty) {
        throw StateError('No published questions');
      }
      final created = await widget.repository.createDraft(
        topicVersionId: '40000000-0000-0000-0000-000000000006',
        title: 'Ecosystems check',
        titleUr: 'ماحول کا جائزہ',
        questionVersionIds: [published.first.id],
      );
      if (!mounted) return;
      setState(() {
        _creating = false;
        _selected = created;
      });
      await _load();
      setState(() => _selected = created);
    } catch (_) {
      if (!mounted) return;
      setState(() => _creating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not create quiz draft')),
      );
    }
  }

  Future<void> _publish(TopicQuiz quiz) async {
    try {
      final published = await widget.repository.publish(quiz.id);
      if (!mounted) return;
      setState(() => _selected = published);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not publish quiz')),
      );
    }
  }

  Future<void> _retire(TopicQuiz quiz) async {
    try {
      final retired = await widget.repository.retire(quiz.id);
      if (!mounted) return;
      setState(() => _selected = retired);
      await _load();
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not retire quiz')),
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
                      child: _QuizList(
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
                          : _QuizDetail(
                              quiz: _selected!,
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

class _QuizList extends StatelessWidget {
  const _QuizList({
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
  final List<TopicQuiz> items;
  final TopicQuiz? selected;
  final TextEditingController search;
  final bool creating;
  final ValueChanged<String> onSearch;
  final ValueChanged<TopicQuiz> onSelect;
  final VoidCallback onCreate;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.topicQuizzesTitle, style: theme.textTheme.headlineSmall),
        const SizedBox(height: NanoSpacing.sm),
        TextField(
          controller: search,
          onChanged: onSearch,
          decoration: const InputDecoration(
            prefixIcon: Icon(Icons.search),
            hintText: 'Search topic or quiz',
          ),
        ),
        const SizedBox(height: NanoSpacing.sm),
        FilledButton.icon(
          onPressed: creating ? null : onCreate,
          icon: const Icon(Icons.add),
          label: Text(copy.newQuizLabel),
        ),
        const SizedBox(height: NanoSpacing.md),
        Expanded(
          child: ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, __) => const SizedBox(height: NanoSpacing.xs),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                selected: item.id == selected?.id,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(NanoRadii.senior),
                ),
                title: Text(item.title),
                subtitle: Text(
                  '${item.topicTitle} · '
                  '${copy.questionStatusLabel(item.status.wireName)} · '
                  '${item.items.length} Q',
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

class _QuizDetail extends StatelessWidget {
  const _QuizDetail({
    required this.quiz,
    required this.copy,
    required this.onPublish,
    required this.onRetire,
  });

  final TopicQuiz quiz;
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
        Text(quiz.titleFor(locale), style: theme.textTheme.headlineSmall),
        const SizedBox(height: NanoSpacing.xs),
        Text(
          '${quiz.topicTitle} · '
          '${copy.questionStatusLabel(quiz.status.wireName)} · v${quiz.version}',
        ),
        Text(
          '${copy.versionIdLabel}: ${quiz.id}',
          style: theme.textTheme.bodySmall,
        ),
        const SizedBox(height: NanoSpacing.xs),
        Text(
          '${copy.passPercentLabel}: ${quiz.policy.passPercent.toStringAsFixed(0)}%',
        ),
        Text(copy.fixedOrderLabel),
        const SizedBox(height: NanoSpacing.md),
        Wrap(
          spacing: NanoSpacing.sm,
          children: [
            if (quiz.status.isEditable)
              FilledButton(
                onPressed: onPublish,
                child: Text(copy.publishQuizLabel),
              ),
            if (quiz.status == QuestionStatus.published)
              OutlinedButton(
                onPressed: onRetire,
                child: Text(copy.retireQuizLabel),
              ),
          ],
        ),
        const SizedBox(height: NanoSpacing.lg),
        Text(copy.quizItemsLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        for (final item in quiz.items) ...[
          Text(
            '${copy.quizItemNumber(item.sortOrder)}: ${item.stemFor(locale)}',
            style: theme.textTheme.titleMedium,
          ),
          const SizedBox(height: NanoSpacing.sm),
        ],
        Text(copy.juniorPreviewLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        _QuizPreview(quiz: quiz, junior: true),
        const SizedBox(height: NanoSpacing.lg),
        Text(copy.seniorPreviewLabel, style: theme.textTheme.titleLarge),
        const SizedBox(height: NanoSpacing.sm),
        _QuizPreview(quiz: quiz, junior: false),
      ],
    );
  }
}

class _QuizPreview extends StatelessWidget {
  const _QuizPreview({required this.quiz, required this.junior});

  final TopicQuiz quiz;
  final bool junior;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale =
        NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final theme = Theme.of(context);
    final first = quiz.items.isEmpty ? null : quiz.items.first;
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
              const CompanionSlot(size: 56),
              const SizedBox(height: NanoSpacing.sm),
            ],
            Text(
              quiz.titleFor(locale),
              style: junior
                  ? theme.textTheme.titleLarge
                  : theme.textTheme.titleMedium,
            ),
            if (first != null) ...[
              const SizedBox(height: NanoSpacing.sm),
              Text(
                junior
                    ? first.stemFor(locale)
                    : '1. ${first.stemFor(locale)}',
                style: theme.textTheme.bodyLarge,
              ),
              for (final option in first.options)
                Padding(
                  padding: const EdgeInsets.only(top: NanoSpacing.xs),
                  child: Text('• ${option.labelFor(locale)}'),
                ),
            ],
            const SizedBox(height: NanoSpacing.sm),
            Text(
              '${copy.versionIdLabel}: ${quiz.id}',
              style: theme.textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}
