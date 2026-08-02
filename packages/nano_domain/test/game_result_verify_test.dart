import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('completion result parses verified xp fields', () {
    final result = GameClientCompletionResult.fromJson({
      'session_id': 's1',
      'status': 'completed',
      'verified': true,
      'verified_score': 3,
      'xp_awarded': 20,
      'message': 'Result verified. XP awarded.',
    });
    expect(result.verified, isTrue);
    expect(result.verifiedScore, 3);
    expect(result.xpAwarded, 20);
  });
}
