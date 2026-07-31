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

  test('a heartbeat credits the time watched, not the time skipped', () async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    final walked = await repo.heartbeat(
      topicVersionId: 'tv-counting-1',
      positionSeconds: 15,
    );
    final jumped = await repo.heartbeat(
      topicVersionId: 'tv-counting-1',
      positionSeconds: 120,
    );

    expect(walked.watchedSeconds, 15);
    // Fifteen seconds of clock cannot pay for 105 seconds of video.
    expect(jumped.watchedSeconds, 33);
    expect(jumped.resumeSeconds, 120, reason: 'resume follows the player head');
  });

  test('a heartbeat never marks a topic completed', () async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    final row = await repo.heartbeat(
      topicVersionId: 'tv-counting-1',
      positionSeconds: 120,
    );
    expect(row.isCompleted, isFalse);
    expect(row.status, TopicProgressStatus.inProgress);
  });

  test('completion is refused until the threshold is credited', () async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    repo.seedWatched('tv-counting-1', 107);
    try {
      await repo.complete('tv-counting-1');
      fail('expected TopicGateException');
    } on TopicGateException catch (error) {
      expect(error.reason, TopicGateReason.notWatchedEnough);
      expect(error.code, 'NL005');
      expect(error.message, contains('Keep watching'));
    }
    expect(repo.completed, isEmpty);
  });

  test('completion happens once and stays put', () async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    repo.seedWatched('tv-counting-1', 110);
    final first = await repo.complete('tv-counting-1');
    final second = await repo.complete('tv-counting-1');

    expect(first.isCompleted, isTrue);
    expect(second.completedAt, first.completedAt);
    expect(repo.completed, ['tv-counting-1'], reason: 'no duplicate event');
  });

  test('a completed topic keeps its status through later heartbeats', () async {
    final repo = FakeLearningProgressRepository();
    await repo.start('tv-counting-1');
    repo.seedWatched('tv-counting-1', 110);
    await repo.complete('tv-counting-1');
    final row = await repo.heartbeat(
      topicVersionId: 'tv-counting-1',
      positionSeconds: 20,
    );
    expect(row.status, TopicProgressStatus.completed);
  });

  test('locked topics refuse heartbeats too', () async {
    final repo = FakeLearningProgressRepository();
    try {
      await repo.heartbeat(
        topicVersionId: 'tv-addition-1',
        positionSeconds: 5,
      );
      fail('expected TopicGateException');
    } on TopicGateException catch (error) {
      expect(error.reason, TopicGateReason.locked);
    }
  });

  test('unlock removes the local gate for fixture flows', () async {
    final repo = FakeLearningProgressRepository();
    repo.unlock('tv-addition-1');
    final row = await repo.start('tv-addition-1');
    expect(row.status, TopicProgressStatus.inProgress);
  });
}
