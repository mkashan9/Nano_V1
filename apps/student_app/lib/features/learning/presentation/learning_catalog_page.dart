import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/learning/presentation/learning_progress_page.dart';
import 'package:student_app/features/learning/presentation/subject_topics_page.dart';
import 'package:student_app/features/learning/presentation/topic_detail_page.dart';

/// LRN-01 catalog browse: illustration-led worlds for Junior, searchable list
/// for Senior. Both shells read the same underlying version IDs.
class LearningCatalogPage extends StatefulWidget {
  const LearningCatalogPage({
    super.key,
    required this.repository,
    this.progressRepository,
    this.checkpointRepository,
    this.insightsRepository,
    this.learnerQuizRepository,
    this.quizAttemptRepository,
    this.companionName,
    this.junior = true,
    this.onTopicOpen,
  });

  final LearningCatalogRepository repository;
  final LearningProgressRepository? progressRepository;
  final CheckpointRepository? checkpointRepository;
  final LearningInsightsRepository? insightsRepository;
  final LearnerQuizRepository? learnerQuizRepository;
  final QuizAttemptRepository? quizAttemptRepository;
  final String? companionName;
  final bool junior;
  final ValueChanged<CatalogTopic>? onTopicOpen;

  @override
  State<LearningCatalogPage> createState() => _LearningCatalogPageState();
}

class _LearningCatalogPageState extends State<LearningCatalogPage> {
  NanoViewState _state = const NanoViewLoading();
  LearningCatalog? _catalog;
  final _query = TextEditingController();

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _state = const NanoViewLoading());
    try {
      final catalog = await widget.repository.loadCatalog();
      if (!mounted) return;
      final copy = NanoLocaleScope.maybeOf(context)?.copy ??
          NanoCopy(NanoAppLocale.en);
      setState(() {
        _catalog = catalog;
        if (catalog.isEmpty) {
          _state = NanoViewEmpty(
            title: copy.catalogEmpty,
            message: copy.emptyMessage,
          );
        } else if (catalog.fromCache) {
          _state = NanoViewOffline(
            lastUpdatedLabel: catalog.updatedAt.toIso8601String(),
          );
        } else {
          _state = const NanoViewReady();
        }
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _state = const NanoViewError());
    }
  }

  void _openSubject(CatalogSubject subject) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => SubjectTopicsPage(
          repository: widget.repository,
          subjectId: subject.subjectId,
          progressRepository: widget.progressRepository,
          checkpointRepository: widget.checkpointRepository,
          learnerQuizRepository: widget.learnerQuizRepository,
          quizAttemptRepository: widget.quizAttemptRepository,
          companionName: widget.companionName,
          junior: widget.junior,
          onTopicOpen: widget.onTopicOpen,
        ),
      ),
    );
  }

  void _openProgress() {
    final insights = widget.insightsRepository;
    if (insights == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => LearningProgressPage(
          repository: insights,
          junior: widget.junior,
          onOpenSuggestion: _openSuggestion,
        ),
      ),
    );
  }

  /// Suggestions carry a topic version id; the catalog we already loaded holds
  /// the rest of the topic. A stale catalog simply reloads instead of guessing.
  Future<void> _openSuggestion(NextUpSuggestion suggestion) async {
    final progress = widget.progressRepository;
    final topic = _catalog?.subjects
        .expand((subject) => subject.topics)
        .where((item) => item.topicVersionId == suggestion.topicVersionId)
        .firstOrNull;
    if (topic == null || progress == null) {
      await _load();
      return;
    }
    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => TopicDetailPage(
          topic: topic,
          progressRepository: progress,
          checkpointRepository: widget.checkpointRepository,
          learnerQuizRepository: widget.learnerQuizRepository,
          quizAttemptRepository: widget.quizAttemptRepository,
          companionName: widget.companionName,
          junior: widget.junior,
          onOpened: widget.onTopicOpen,
        ),
      ),
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    final locale = NanoLocaleScope.maybeOf(context)?.locale ?? NanoAppLocale.en;
    final catalog = _catalog;
    final visible = catalog == null
        ? const <CatalogSubject>[]
        : widget.junior
            ? catalog.subjects
            : catalog.search(_query.text);
    return Scaffold(
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: catalog == null
            ? const SizedBox.shrink()
            : NanoResponsiveBuilder(
                builder: (context, windowSize, _) {
                  final columns = NanoResponsive.subjectColumnsFor(
                    size: windowSize,
                    junior: widget.junior,
                  );
                  return NanoMaxContentWidth(
                    child: ListView(
                      padding: const EdgeInsets.fromLTRB(
                        NanoSpacing.md,
                        NanoSpacing.md,
                        NanoSpacing.md,
                        NanoSpacing.xxl,
                      ),
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                copy.catalogTitle,
                                style:
                                    Theme.of(context).textTheme.headlineSmall,
                              ),
                            ),
                            if (widget.insightsRepository != null)
                              TextButton.icon(
                                onPressed: _openProgress,
                                icon: const Icon(Icons.trending_up),
                                label: Text(copy.progressTitle),
                              ),
                          ],
                        ),
                        if (!widget.junior) ...[
                          const SizedBox(height: NanoSpacing.md),
                          TextField(
                            controller: _query,
                            onChanged: (_) => setState(() {}),
                            decoration: InputDecoration(
                              hintText: copy.catalogSearchHint,
                              prefixIcon: const Icon(Icons.search),
                              border: const OutlineInputBorder(),
                            ),
                          ),
                        ],
                        const SizedBox(height: NanoSpacing.lg),
                        if (visible.isEmpty)
                          Text(copy.catalogNoResults)
                        else if (widget.junior)
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: visible.length,
                            gridDelegate:
                                SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: columns,
                              mainAxisSpacing: NanoSpacing.sm,
                              crossAxisSpacing: NanoSpacing.sm,
                              childAspectRatio: 1.05,
                            ),
                            itemBuilder: (context, index) {
                              final subject = visible[index];
                              return JuniorActionCard(
                                title: subject.titleFor(locale),
                                subtitle:
                                    copy.topicCount(subject.topics.length),
                                backgroundColor:
                                    Color(subject.worldColorValue),
                                onTap: () => _openSubject(subject),
                              );
                            },
                          )
                        else
                          for (final subject in visible)
                            Padding(
                              padding: const EdgeInsets.only(
                                bottom: NanoSpacing.sm,
                              ),
                              child: SeniorProgressCard(
                                title: subject.titleFor(locale),
                                tag: copy.topicsDone(
                                  subject.completedTopics,
                                  subject.topics.length,
                                ),
                                progress: subject.progress,
                                meta: subject.remainingMinutes == 0
                                    ? null
                                    : copy.minutesLabel(
                                        subject.remainingMinutes,
                                      ),
                                onTap: () => _openSubject(subject),
                              ),
                            ),
                      ],
                    ),
                  );
                },
              ),
      ),
    );
  }
}
