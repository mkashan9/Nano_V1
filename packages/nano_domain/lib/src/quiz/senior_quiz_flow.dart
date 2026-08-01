import 'topic_quiz.dart';

/// Local Senior attempt state: free navigation, review, no client scoring.
class SeniorQuizFlow {
  SeniorQuizFlow({
    required this.quiz,
    this.currentIndex = 0,
    Map<String, String>? selections,
    this.reviewing = false,
    this.finished = false,
  }) : selections = Map<String, String>.from(selections ?? const {});

  factory SeniorQuizFlow.start(TopicQuiz quiz) {
    if (!quiz.isLearnerSafe) {
      throw ArgumentError('Senior quiz requires learner-safe options');
    }
    if (quiz.items.isEmpty) {
      throw ArgumentError('Senior quiz needs at least one question');
    }
    return SeniorQuizFlow(quiz: quiz);
  }

  final TopicQuiz quiz;
  final int currentIndex;
  final Map<String, String> selections;
  final bool reviewing;
  final bool finished;

  QuizItem get currentItem => quiz.items[currentIndex];

  int get questionCount => quiz.items.length;

  int get answeredCount => selections.length;

  bool get hasSelection =>
      selections.containsKey(currentItem.questionVersionId);

  String? get selectedOptionId => selections[currentItem.questionVersionId];

  bool get isFirstQuestion => currentIndex <= 0;

  bool get isLastQuestion => currentIndex >= questionCount - 1;

  bool get allAnswered => answeredCount == questionCount;

  bool get canFinish => allAnswered && !finished;

  List<int> get unansweredIndexes => [
        for (var i = 0; i < quiz.items.length; i++)
          if (!selections.containsKey(quiz.items[i].questionVersionId)) i,
      ];

  bool isAnswered(int index) =>
      selections.containsKey(quiz.items[index].questionVersionId);

  SeniorQuizFlow select(String optionId) {
    if (finished) return this;
    final next = Map<String, String>.from(selections);
    next[currentItem.questionVersionId] = optionId;
    return SeniorQuizFlow(
      quiz: quiz,
      currentIndex: currentIndex,
      selections: next,
      reviewing: reviewing,
      finished: false,
    );
  }

  SeniorQuizFlow jumpTo(int index) {
    if (finished) return this;
    if (index < 0 || index >= questionCount) return this;
    return SeniorQuizFlow(
      quiz: quiz,
      currentIndex: index,
      selections: selections,
      reviewing: false,
      finished: false,
    );
  }

  SeniorQuizFlow goNext() {
    if (finished || isLastQuestion) return this;
    return jumpTo(currentIndex + 1);
  }

  SeniorQuizFlow goPrevious() {
    if (finished || isFirstQuestion) return this;
    return jumpTo(currentIndex - 1);
  }

  SeniorQuizFlow enterReview() {
    if (finished) return this;
    return SeniorQuizFlow(
      quiz: quiz,
      currentIndex: currentIndex,
      selections: selections,
      reviewing: true,
      finished: false,
    );
  }

  SeniorQuizFlow exitReview() {
    if (finished) return this;
    return SeniorQuizFlow(
      quiz: quiz,
      currentIndex: currentIndex,
      selections: selections,
      reviewing: false,
      finished: false,
    );
  }

  SeniorQuizFlow finish() {
    if (!canFinish) return this;
    return SeniorQuizFlow(
      quiz: quiz,
      currentIndex: currentIndex,
      selections: selections,
      reviewing: false,
      finished: true,
    );
  }
}
