import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

CatalogTopic _topic({
  TopicProgressStatus status = TopicProgressStatus.notStarted,
  List<String> blocking = const [],
  double progress = 0,
  int resumeSeconds = 0,
}) {
  return CatalogTopic(
    topicId: 't1',
    topicVersionId: 'tv1',
    slug: 'counting',
    title: 'Counting to 20',
    order: 1,
    estimatedMinutes: 12,
    status: status,
    progress: progress,
    resumeSeconds: resumeSeconds,
    blockingTitles: blocking,
  );
}

void main() {
  test('locked topics always win over progress state', () {
    expect(
      TopicActionPolicy.forTopic(
        _topic(
          status: TopicProgressStatus.inProgress,
          blocking: const ['Counting to 20'],
          resumeSeconds: 30,
        ),
      ),
      TopicAction.locked,
    );
  });

  test('action matches start, resume, and review states', () {
    expect(TopicActionPolicy.forTopic(_topic()), TopicAction.start);
    expect(
      TopicActionPolicy.forTopic(
        _topic(
          status: TopicProgressStatus.inProgress,
          progress: 0.4,
          resumeSeconds: 90,
        ),
      ),
      TopicAction.resume,
    );
    expect(
      TopicActionPolicy.forTopic(
        _topic(status: TopicProgressStatus.completed, progress: 1),
      ),
      TopicAction.review,
    );
  });

  test('applyProgress refreshes status without inventing unlocks', () {
    final locked = _topic(blocking: const ['Counting to 20']);
    final updated = TopicActionPolicy.applyProgress(
      locked,
      const TopicProgress(
        userId: 'u1',
        topicVersionId: 'tv1',
        status: TopicProgressStatus.inProgress,
        progress: 0.2,
        resumeSeconds: 12,
      ),
    );
    expect(updated.isLocked, isTrue);
    expect(updated.blockingTitles, ['Counting to 20']);
    expect(updated.status, TopicProgressStatus.inProgress);
    expect(updated.resumeSeconds, 12);
  });

  test('gate reason codes map to enums', () {
    expect(TopicGateReason.fromCode('NL001'), TopicGateReason.locked);
    expect(TopicGateReason.fromCode('NL002'), TopicGateReason.unavailable);
    expect(TopicGateReason.fromCode('NL003'), TopicGateReason.notLearner);
    expect(TopicGateReason.fromCode('other'), TopicGateReason.unknown);
  });

  test('action labels stay in sync with copy', () {
    final copy = NanoCopy(NanoAppLocale.en);
    expect(TopicAction.start.label(copy), 'Start');
    expect(TopicAction.resume.label(copy), 'Resume');
    expect(TopicAction.review.label(copy), 'Review');
    expect(TopicAction.locked.label(copy), 'Locked');
  });
}
