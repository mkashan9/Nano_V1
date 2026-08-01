import 'package:admin_web/features/content/presentation/learning_catalog_admin_page.dart';
import 'package:admin_web/features/content/presentation/question_bank_page.dart';
import 'package:admin_web/features/content/presentation/topic_quiz_page.dart';
import 'package:flutter/material.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_design_system/nano_design_system.dart';
import 'package:nano_domain/nano_domain.dart';

/// Superadmin Content hub: catalog (ADM-04), question bank (QZ-01), quizzes (QZ-02).
class ContentHubPage extends StatelessWidget {
  const ContentHubPage({
    super.key,
    required this.questionBankRepository,
    required this.topicQuizRepository,
    required this.learningContentRepository,
  });

  final QuestionBankRepository questionBankRepository;
  final TopicQuizRepository topicQuizRepository;
  final LearningContentRepository learningContentRepository;

  @override
  Widget build(BuildContext context) {
    final copy = NanoLocaleScope.maybeOf(context)?.copy ??
        NanoCopy(NanoAppLocale.en);
    return DefaultTabController(
      length: 3,
      child: Column(
        children: [
          Material(
            color: Theme.of(context).colorScheme.surface,
            child: TabBar(
              tabs: [
                Tab(text: copy.learningCatalogTitle),
                Tab(text: copy.questionBankTitle),
                Tab(text: copy.topicQuizzesTitle),
              ],
            ),
          ),
          Expanded(
            child: TabBarView(
              children: [
                LearningCatalogAdminPage(
                  repository: learningContentRepository,
                ),
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
