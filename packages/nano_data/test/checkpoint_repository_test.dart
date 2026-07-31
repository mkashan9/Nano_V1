import 'package:nano_data/nano_data.dart';
import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  group('FakeCheckpointRepository', () {
    test('returns a topic\'s checkpoints in order', () async {
      final repository = FakeCheckpointRepository();
      final checkpoints =
          await repository.forTopicVersion('tv-ecosystems-1');
      expect(
        checkpoints.map((checkpoint) => checkpoint.atSeconds),
        [660, 1320, 1800],
      );
      expect(
        checkpoints.where((checkpoint) => checkpoint.isRequired).single.id,
        'cp-1320',
      );
    });

    test('a topic without refresh moments returns nothing', () async {
      final repository = FakeCheckpointRepository();
      expect(await repository.forTopicVersion('tv-counting-1'), isEmpty);
    });

    test('acknowledging records the response and is idempotent', () async {
      final repository = FakeCheckpointRepository();
      await repository.acknowledge(
        checkpointId: 'cp-1320',
        response: CheckpointResponse.answered,
      );
      await repository.acknowledge(
        checkpointId: 'cp-1320',
        response: CheckpointResponse.continued,
      );
      expect(
        await repository.answeredIds('tv-ecosystems-1'),
        {'cp-1320'},
      );
      expect(repository.responses, [
        CheckpointResponse.answered,
        CheckpointResponse.continued,
      ]);
    });

    test('answers from another topic do not leak in', () async {
      final repository = FakeCheckpointRepository();
      await repository.acknowledge(
        checkpointId: 'cp-elsewhere',
        response: CheckpointResponse.continued,
      );
      expect(await repository.answeredIds('tv-ecosystems-1'), isEmpty);
    });
  });

  group('credit gate in the progress repository', () {
    test('watch credit stops at the gate and resumes once it clears', () async {
      final progress = FakeLearningProgressRepository(
        creditGates: {'tv-ecosystems-1': 1320},
      );
      await progress.start('tv-ecosystems-1');
      progress.seedWatched('tv-ecosystems-1', 1310);

      var row = await progress.heartbeat(
        topicVersionId: 'tv-ecosystems-1',
        positionSeconds: 1400,
      );
      expect(row.watchedSeconds, 1320);

      // A second beat past the gate earns nothing while it stands.
      row = await progress.heartbeat(
        topicVersionId: 'tv-ecosystems-1',
        positionSeconds: 1415,
      );
      expect(row.watchedSeconds, 1320);

      progress.clearGate('tv-ecosystems-1');
      row = await progress.heartbeat(
        topicVersionId: 'tv-ecosystems-1',
        positionSeconds: 1430,
      );
      expect(row.watchedSeconds, 1335);
    });

    test('completion still needs the threshold on a long video', () async {
      final progress = FakeLearningProgressRepository();
      await progress.start('tv-ecosystems-1');
      progress.seedWatched('tv-ecosystems-1', 2100);
      await expectLater(
        progress.complete('tv-ecosystems-1'),
        throwsA(
          isA<TopicGateException>().having(
            (error) => error.reason,
            'reason',
            TopicGateReason.notWatchedEnough,
          ),
        ),
      );

      progress.seedWatched('tv-ecosystems-1', 2160);
      final row = await progress.complete('tv-ecosystems-1');
      expect(row.isCompleted, isTrue);
    });
  });
}
