import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:student_app/features/learning/presentation/learning_progress_page.dart';
import 'package:student_app/features/learning/presentation/subject_topics_page.dart';
import 'package:student_app/features/learning/presentation/topic_detail_page.dart';
import 'package:student_app/features/learning/visual/junior_learning_visual_assets.dart';

/// LRN-01 / VIS-02 catalog browse: illustration-led worlds for Junior,
/// searchable list for Senior. Both shells read the same underlying version IDs.
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
    this.learnerDisplayName,
    this.shareCards,
    this.junior = true,
    this.useVisualAssets = true,
    this.onTopicOpen,
  });

  final LearningCatalogRepository repository;
  final LearningProgressRepository? progressRepository;
  final CheckpointRepository? checkpointRepository;
  final LearningInsightsRepository? insightsRepository;
  final LearnerQuizRepository? learnerQuizRepository;
  final QuizAttemptRepository? quizAttemptRepository;
  final String? companionName;
  final String? learnerDisplayName;
  final ShareCardRepository? shareCards;
  final bool junior;
  final bool useVisualAssets;
  final ValueChanged<CatalogTopic>? onTopicOpen;

  @override
  State<LearningCatalogPage> createState() => _LearningCatalogPageState();
}

class _LearningCatalogPageState extends State<LearningCatalogPage> {
  NanoViewState _state = const NanoViewLoading();
  LearningCatalog? _catalog;
  final _query = TextEditingController();
  late final PageController _carousel;
  var _carouselIndex = 0;

  @override
  void initState() {
    super.initState();
    _carousel = PageController(viewportFraction: 0.82);
    _load();
  }

  @override
  void dispose() {
    _query.dispose();
    _carousel.dispose();
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
          learnerDisplayName: widget.learnerDisplayName,
          shareCards: widget.shareCards,
          junior: widget.junior,
          onTopicOpen: widget.onTopicOpen,
        ),
      ),
    );
  }

  Future<void> _openTopic(CatalogTopic topic) async {
    final progress = widget.progressRepository;
    if (progress == null) {
      widget.onTopicOpen?.call(topic);
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
          learnerDisplayName: widget.learnerDisplayName,
          shareCards: widget.shareCards,
          junior: widget.junior,
          onOpened: widget.onTopicOpen,
        ),
      ),
    );
    await _load();
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
    await _openTopic(topic);
  }

  CatalogTopic? _continueTopic(LearningCatalog catalog) {
    for (final subject in catalog.subjects) {
      final next = subject.nextTopic;
      if (next != null && next.canResume) return next;
    }
    for (final subject in catalog.subjects) {
      final next = subject.nextTopic;
      if (next != null) return next;
    }
    return null;
  }

  ImageProvider? _worldArt(String slug) {
    if (!widget.useVisualAssets) return null;
    return switch (slug) {
      'math' => const AssetImage(JuniorLearningVisualAssets.numbersWorld),
      'english' => const AssetImage(JuniorLearningVisualAssets.englishWorld),
      'stories' => const AssetImage(JuniorLearningVisualAssets.storiesWorld),
      _ => null,
    };
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
                .where((s) => s.slug != 'space')
                .toList(growable: false)
            : catalog.search(_query.text);
    return Scaffold(
      backgroundColor: widget.junior ? NanoColors.canvas : null,
      body: NanoViewStateHost(
        state: _state,
        onRetry: _load,
        child: catalog == null
            ? const SizedBox.shrink()
            : widget.junior
                ? _buildJunior(context, copy, locale, catalog, visible)
                : _buildSenior(context, copy, locale, visible),
      ),
    );
  }

  Widget _buildJunior(
    BuildContext context,
    NanoCopy copy,
    NanoAppLocale locale,
    LearningCatalog catalog,
    List<CatalogSubject> visible,
  ) {
    final continueTopic = _continueTopic(catalog);
    return ListView(
      padding: const EdgeInsets.fromLTRB(
        0,
        NanoSpacing.md,
        0,
        NanoSpacing.xxl,
      ),
      children: [
        JuniorLearningPromptHeader(
          prompt: copy.learningPrompt,
          foxIllustration: widget.useVisualAssets
              ? const AssetImage(JuniorLearningVisualAssets.foxPrompt)
              : null,
          onSearch: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(copy.catalogSearchHint)),
            );
          },
          onMic: () {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text(copy.learningVoiceHint)),
            );
          },
        ),
        const SizedBox(height: NanoSpacing.lg),
        SizedBox(
          height: MediaQuery.sizeOf(context).shortestSide < 500 ? 240 : 360,
          child: PageView.builder(
            controller: _carousel,
            itemCount: visible.length,
            onPageChanged: (i) => setState(() => _carouselIndex = i),
            itemBuilder: (context, index) {
              final subject = visible[index];
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8),
                child: JuniorLearningWorldCarouselCard(
                  title: subject.titleFor(locale),
                  playLabel: copy.playLabel,
                  backgroundColor: Color(subject.worldColorValue),
                  filledStars: 2,
                  illustration: _worldArt(subject.slug),
                  onPlay: () => _openSubject(subject),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: NanoSpacing.sm),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            for (var i = 0; i < visible.length; i++)
              Container(
                width: i == _carouselIndex ? 18 : 10,
                height: 8,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(NanoRadii.pill),
                  color: i == _carouselIndex
                      ? const Color(0xFF7B61FF)
                      : const Color(0xFF3A4060),
                ),
              ),
          ],
        ),
        const SizedBox(height: NanoSpacing.xl),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
          child: Text(
            copy.continueWhereStopped,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                ),
          ),
        ),
        const SizedBox(height: NanoSpacing.sm),
        if (continueTopic != null)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: NanoSpacing.md),
            child: JuniorLearningContinueCard(
              title: continueTopic.titleFor(locale),
              subtitle: copy.lessonLabel(continueTopic.order),
              playLabel: copy.playLabel,
              progress: continueTopic.progress,
              filledStars: continueTopic.progress >= 0.66
                  ? 3
                  : continueTopic.progress >= 0.33
                      ? 2
                      : 1,
              illustration: widget.useVisualAssets
                  ? const AssetImage(JuniorLearningVisualAssets.spaceContinue)
                  : null,
              onPlay: () => _openTopic(continueTopic),
            ),
          ),
        if (widget.insightsRepository != null) ...[
          const SizedBox(height: NanoSpacing.md),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: _openProgress,
              child: Text(copy.progressTitle),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSenior(
    BuildContext context,
    NanoCopy copy,
    NanoAppLocale locale,
    List<CatalogSubject> visible,
  ) {
    return NanoResponsiveBuilder(
      builder: (context, windowSize, _) {
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
                      style: Theme.of(context).textTheme.headlineSmall,
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
              const SizedBox(height: NanoSpacing.lg),
              if (visible.isEmpty)
                Text(copy.catalogNoResults)
              else
                for (final subject in visible)
                  Padding(
                    padding: const EdgeInsets.only(bottom: NanoSpacing.sm),
                    child: SeniorProgressCard(
                      title: subject.titleFor(locale),
                      tag: copy.topicsDone(
                        subject.completedTopics,
                        subject.topics.length,
                      ),
                      progress: subject.progress,
                      meta: subject.remainingMinutes == 0
                          ? null
                          : copy.minutesLabel(subject.remainingMinutes),
                      onTap: () => _openSubject(subject),
                    ),
                  ),
            ],
          ),
        );
      },
    );
  }
}
