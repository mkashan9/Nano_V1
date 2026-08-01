import '../l10n/nano_app_locale.dart';
import 'topic_quiz.dart';

/// Gentle companion mood during a Junior attempt (scoring is QZ-05).
enum CompanionQuizMood {
  ready,
  listening,
  encouraging,
  finished,
}

/// Local Junior attempt state: one question on screen, ordered advance,
/// no client-side scoring.
class JuniorQuizFlow {
  JuniorQuizFlow({
    required this.quiz,
    this.currentIndex = 0,
    Map<String, String>? selections,
    this.finished = false,
  }) : selections = Map<String, String>.from(selections ?? const {});

  factory JuniorQuizFlow.start(TopicQuiz quiz) {
    if (!quiz.isLearnerSafe) {
      throw ArgumentError('Junior quiz requires learner-safe options');
    }
    if (quiz.items.isEmpty) {
      throw ArgumentError('Junior quiz needs at least one question');
    }
    return JuniorQuizFlow(quiz: quiz);
  }

  factory JuniorQuizFlow.resume(
    TopicQuiz quiz,
    Map<String, String> selections,
  ) {
    JuniorQuizFlow.start(quiz);
    final index = quiz.items.indexWhere(
      (item) => !selections.containsKey(item.questionVersionId),
    );
    return JuniorQuizFlow(
      quiz: quiz,
      currentIndex: index < 0 ? quiz.items.length - 1 : index,
      selections: selections,
      finished: false,
    );
  }

  final TopicQuiz quiz;
  final int currentIndex;
  final Map<String, String> selections;
  final bool finished;

  QuizItem get currentItem => quiz.items[currentIndex];

  int get questionCount => quiz.items.length;

  int get answeredCount => selections.length;

  bool get hasSelection =>
      selections.containsKey(currentItem.questionVersionId);

  String? get selectedOptionId =>
      selections[currentItem.questionVersionId];

  bool get isLastQuestion => currentIndex >= questionCount - 1;

  bool get canAdvance => hasSelection && !finished;

  CompanionQuizMood get mood {
    if (finished) return CompanionQuizMood.finished;
    if (hasSelection) return CompanionQuizMood.encouraging;
    if (answeredCount > 0) return CompanionQuizMood.listening;
    return CompanionQuizMood.ready;
  }

  double get progressRatio =>
      questionCount == 0 ? 0 : (currentIndex + (finished ? 1 : 0)) / questionCount;

  JuniorQuizFlow select(String optionId) {
    if (finished) return this;
    final next = Map<String, String>.from(selections);
    next[currentItem.questionVersionId] = optionId;
    return JuniorQuizFlow(
      quiz: quiz,
      currentIndex: currentIndex,
      selections: next,
      finished: false,
    );
  }

  JuniorQuizFlow advance() {
    if (!canAdvance) return this;
    if (isLastQuestion) {
      return JuniorQuizFlow(
        quiz: quiz,
        currentIndex: currentIndex,
        selections: selections,
        finished: true,
      );
    }
    return JuniorQuizFlow(
      quiz: quiz,
      currentIndex: currentIndex + 1,
      selections: selections,
      finished: false,
    );
  }

  String promptFor(NanoAppLocale locale, {String companionName = 'Nori'}) {
    final ur = locale == NanoAppLocale.ur;
    switch (mood) {
      case CompanionQuizMood.ready:
        return ur
            ? '$companionName کہتا ہے: آہستہ پڑھیں اور ایک جواب چنیں۔'
            : '$companionName says: Read slowly and pick one answer.';
      case CompanionQuizMood.listening:
        return ur
            ? '$companionName سن رہا ہے — اگلا سوال تیار ہے۔'
            : '$companionName is listening — the next question is ready.';
      case CompanionQuizMood.encouraging:
        return ur
            ? 'اچھا انتخاب! جب تیار ہوں تو آگے بڑھیں۔'
            : 'Nice choice! Move on when you are ready.';
      case CompanionQuizMood.finished:
        return ur
            ? '$companionName خوش ہے! اسکور بعد میں محفوظ ہوگا۔'
            : '$companionName is proud! Your score will be saved later.';
    }
  }
}
