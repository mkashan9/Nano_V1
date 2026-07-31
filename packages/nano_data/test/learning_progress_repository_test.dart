import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('start opens an unlocked topic and is idempotent', () async {
    final repo = FakeLearningProgressRepository();
    final first = await repo.start('tv-counting-1');
    final second = await repo.start('tv-counting-1');
    expect(first.status, TopicProgressStatus.inProgress);
    expect(second.status, TopicProgressStatus.inProgress);
    expect(repo.started, ['tv-counting-1', 'tv-counting-1']);
  });

  test('start refuses a locked topic with NL001', () async {
    final repo = FakeLearningProgressRepository();
    try {
      await repo.start('tv-addition-1');
      fail('expected TopicGateException');
    } on TopicGateException catch (error) {
      expect(error.reason, TopicGateReason.locked);
      expect(error.code, 'NL001');
      expect(error.message, contains('Finish'));
    }
  });

  test('start refuses an unavailable topic with NL002', () async {
    final repo = FakeLearningProgressRepository();
    try {
      await repo.start('tv-first-loop-1');
      fail('expected TopicGateException');
    } on TopicGateException catch (error) {
      expect(error.reason, TopicGateReason.unavailable);
      expect(error.code, 'NL002');
    }
  });

  test('saveProgress clamps and never lowers progress', () async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    final mid = await repo.saveProgress(
      topicVersionId: 'tv-counting-1',
      resumeSeconds: 45,
      progress: 0.4,
    );
    final late = await repo.saveProgress(
      topicVersionId: 'tv-counting-1',
      resumeSeconds: 10,
      progress: 0.1,
    );
    expect(mid.progress, 0.4);
    expect(late.progress, 0.4);
    expect(late.resumeSeconds, 10);
  });

  test('saveProgress never marks a topic completed', () async {
    final repo = FakeLearningProgressRepository();
    final row = await repo.saveProgress(
      topicVersionId: 'tv-counting-1',
      resumeSeconds: 120,
      progress: 1.5,
    );
    expect(row.progress, 1.0);
    expect(row.status, TopicProgressStatus.inProgress);
    expect(row.isCompleted, isFalse);
  });

  test('unlock removes the local gate for fixture flows', () async {
    final repo = FakeLearningProgressRepository();
    repo.unlock('tv-addition-1');
    final row = await repo.start('tv-addition-1');
    expect(row.status, TopicProgressStatus.inProgress);
  });
}
