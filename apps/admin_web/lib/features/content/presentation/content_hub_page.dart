import 'package:admin_web/features/content/presentation/question_bank_page.dart';
import 'package:admin_web/features/content/presentation/topic_quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// Superadmin Content hub: question bank (QZ-01) and topic quizzes (QZ-02).
class ContentHubPage extends StatelessWidget {
  const ContentHubPage({
    super.key,
    required this.questionBankRepository,
    required this.topicQuizRepository,
  });

  final QuestionBankRepository questionBankRepository;
  final TopicQuizRepository topicQuizRepository;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    return DefaultTabController(
      length: 2,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                Tab(text: copy.questionBankTitle),
                Tab(text: copy.topicQuizzesTitle),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                QuestionBankPage(repository: questionBankRepository),
                TopicQuizPage(
                  repository: topicQuizRepository,
                  questionBank: questionBankRepository,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
