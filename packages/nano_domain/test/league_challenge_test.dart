import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('LeagueChallenge parses respond and rematch fields', () {
    final challenge = LeagueChallenge.fromJson({
      'id': 'c1',
      'status': 'completed',
      'rule_slug': 'number_rush_duel',
      'title_en': 'Number Rush duel',
      'title_ur': '',
      'peer_label': 'Sara',
      'i_am_challenger': true,
      'expires_at': '2026-08-03T00:00:00Z',
      'game_version_id': 'v1',
      'my_score': 5,
      'peer_score': 3,
      'outcome': 'challenger_win',
      'rematch_of': null,
    });
    expect(challenge.canRematch, isTrue);
    expect(challenge.outcome, LeagueChallengeOutcome.challengerWin);
    expect(
      const LeagueBoardEntry(
        rank: 1,
        weekXp: 10,
        displayLabel: 'Sara',
        targetToken: 'abc',
      ).canChallenge,
      isTrue,
    );
  });
}
