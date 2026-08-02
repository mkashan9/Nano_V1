import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('FriendsLeaderboard parses ranks without user ids', () {
    final board = FriendsLeaderboard.fromJson({
      'week_key': '2026-W31',
      'my_rank': 2,
      'my_week_xp': 40,
      'friend_count': 1,
      'entries': [
        {
          'rank': 1,
          'week_xp': 90,
          'display_label': 'sara',
          'is_me': false,
        },
        {
          'rank': 2,
          'week_xp': 40,
          'display_label': 'ali',
          'is_me': true,
        },
      ],
    });
    expect(board.entries, hasLength(2));
    expect(board.entries.first.displayLabel, 'sara');
    expect(board.entries.last.isMe, isTrue);
    expect(board.myRank, 2);
  });
}
