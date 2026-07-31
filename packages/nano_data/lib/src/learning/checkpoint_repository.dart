import 'package:nano_domain/nano_domain.dart';
import 'package:supabase/supabase.dart';

/// Reads a topic's refresh checkpoints and records the learner's answers.
///
/// Reads are ordinary RLS-filtered selects; the answer is an RPC because
/// clearing a required checkpoint also releases a server-side credit gate.
abstract class CheckpointRepository {
  Future<List<RefreshCheckpoint>> forTopicVersion(String topicVersionId);

  Future<Set<String>> answeredIds(String topicVersionId);

  Future<void> acknowledge({
    required String checkpointId,
    required CheckpointResponse response,
  });
}

class FakeCheckpointRepository implements CheckpointRepository {
  FakeCheckpointRepository({List<RefreshCheckpoint>? checkpoints})
      : checkpoints = checkpoints ?? _fixture;

  static const _fixture = [
    RefreshCheckpoint(
      id: 'cp-660',
      topicVersionId: 'tv-ecosystems-1',
      atSeconds: 660,
      kind: CheckpointKind.stretch,
      prompt: 'Stand up and stretch for a moment.',
      promptUr: 'ایک لمحے کے لیے کھڑے ہو کر جسم کو ڈھیلا کریں۔',
    ),
    RefreshCheckpoint(
      id: 'cp-1320',
      topicVersionId: 'tv-ecosystems-1',
      atSeconds: 1320,
      kind: CheckpointKind.recall,
      prompt:
          'Before the last part: name one thing that keeps an ecosystem in '
          'balance.',
      promptUr:
          'آخری حصے سے پہلے: ایک چیز بتائیں جو ماحولیاتی نظام کا توازن رکھتی ہے۔',
      isRequired: true,
    ),
    RefreshCheckpoint(
      id: 'cp-1800',
      topicVersionId: 'tv-ecosystems-1',
      atSeconds: 1800,
      kind: CheckpointKind.stretch,
      prompt: 'Stand up and stretch for a moment.',
      promptUr: 'ایک لمحے کے لیے کھڑے ہو کر جسم کو ڈھیلا کریں۔',
    ),
  ];

  final List<RefreshCheckpoint> checkpoints;
  final Set<String> answered = {};
  final List<CheckpointResponse> responses = [];

  @override
  Future<List<RefreshCheckpoint>> forTopicVersion(
    String topicVersionId,
  ) async {
    return [
      for (final checkpoint in checkpoints)
        if (checkpoint.topicVersionId == topicVersionId) checkpoint,
    ]..sort((a, b) => a.atSeconds.compareTo(b.atSeconds));
  }

  @override
  Future<Set<String>> answeredIds(String topicVersionId) async {
    final ids = {
      for (final checkpoint in checkpoints)
        if (checkpoint.topicVersionId == topicVersionId) checkpoint.id,
    };
    return answered.intersection(ids);
  }

  @override
  Future<void> acknowledge({
    required String checkpointId,
    required CheckpointResponse response,
  }) async {
    answered.add(checkpointId);
    responses.add(response);
  }
}

class SupabaseCheckpointRepository implements CheckpointRepository {
  SupabaseCheckpointRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<List<RefreshCheckpoint>> forTopicVersion(
    String topicVersionId,
  ) async {
    final rows = await _client
        .from('refresh_checkpoints')
        .select(
          'id, topic_version_id, at_seconds, kind, prompt, prompt_ur, '
          'is_required',
        )
        .eq('topic_version_id', topicVersionId)
        .order('at_seconds');
    return [
      for (final row in rows as List)
        RefreshCheckpoint.fromRow(Map<String, dynamic>.from(row as Map)),
    ];
  }

  @override
  Future<Set<String>> answeredIds(String topicVersionId) async {
    final rows = await _client
        .from('checkpoint_events')
        .select('checkpoint_id')
        .eq('topic_version_id', topicVersionId);
    return {
      for (final row in rows as List)
        (row as Map)['checkpoint_id'] as String,
    };
  }

  @override
  Future<void> acknowledge({
    required String checkpointId,
    required CheckpointResponse response,
  }) async {
    await _client.rpc(
      'acknowledge_checkpoint',
      params: {
        'p_checkpoint_id': checkpointId,
        'p_response': response.wireName,
      },
    );
  }
}
