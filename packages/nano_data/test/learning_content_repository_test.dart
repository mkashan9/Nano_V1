import 'package:flutter_test/flutter_test.dart';
import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('create and publish subject then topic', () async {
    final repo = FakeLearningContentRepository();
    final subject = await repo.createSubjectDraft(
      slug: 'history',
      title: 'History',
      summary: 'Past events',
    );
    expect(subject.isDraft, isTrue);
    final publishedSubject = await repo.publishSubject(subject.subjectVersionId);
    expect(publishedSubject.isPublished, isTrue);

    final topic = await repo.createTopicDraft(
      subjectId: subject.subjectId,
      slug: 'empires',
      title: 'Empires',
      videoProvider: 'fixture',
      videoRef: 'fixture://empires',
    );
    expect(topic.isDraft, isTrue);
    final publishedTopic = await repo.publishTopic(topic.topicVersionId);
    expect(publishedTopic.isPublished, isTrue);
  });

  test('topic publish blocked until subject published', () async {
    final repo = FakeLearningContentRepository();
    final coding = (await repo.listSubjects())
        .firstWhere((s) => s.slug == 'coding');
    expect(coding.isDraft, isTrue);
    expect(
      () => repo.publishTopic(coding.topics.first.topicVersionId),
      throwsStateError,
    );
  });
}
