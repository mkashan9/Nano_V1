import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('publish policy requires title and media', () {
    const ready = AuthoringTopic(
      topicId: 't1',
      slug: 'loop',
      topicVersionId: 'tv1',
      title: 'Loops',
      status: CatalogPublishStatus.draft,
      order: 1,
      videoProvider: 'fixture',
      videoRef: 'fixture://loop',
    );
    const missingMedia = AuthoringTopic(
      topicId: 't2',
      slug: 'loop',
      topicVersionId: 'tv2',
      title: 'Loops',
      status: CatalogPublishStatus.draft,
      order: 1,
    );
    expect(LearningContentPublishPolicy.topicReady(ready), isTrue);
    expect(LearningContentPublishPolicy.topicReady(missingMedia), isFalse);
  });

  test('authoring subject parses topics', () {
    final subject = AuthoringSubject.fromJson({
      'subject_id': '10000000-0000-0000-0000-000000000001',
      'subject_slug': 'math',
      'subject_version_id': '20000000-0000-0000-0000-000000000001',
      'subject_title': 'Math',
      'subject_status': 'published',
      'topics': [
        {
          'topic_id': '30000000-0000-0000-0000-000000000001',
          'topic_slug': 'counting',
          'topic_version_id': '40000000-0000-0000-0000-000000000001',
          'title': 'Counting to 20',
          'status': 'draft',
          'topic_order': 1,
        },
      ],
    });
    expect(subject.isPublished, isTrue);
    expect(subject.topics.single.isDraft, isTrue);
  });
}
