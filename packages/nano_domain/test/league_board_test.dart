import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('LeagueBoard parses privacy-safe entries', () {
    final board = LeagueBoard.fromJson({
      'joined': true,
      'week_key': '2026-W31',
      'my_rank': 2,
      'my_week_xp': 40,
      'division_slug': 'bronze',
      'division_title_en': 'Bronze',
      'division_title_ur': 'کانسی',
      'entries': [
        {
          'rank': 1,
          'week_xp': 80,
          'display_label': 'Sara',
          'is_me': false,
        },
        {
          'rank': 2,
          'week_xp': 40,
          'display_label': 'Ali',
          'is_me': true,
        },
      ],
    });
    expect(board.joined, isTrue);
    expect(board.entries, hasLength(2));
    expect(board.entries.first.displayLabel, 'Sara');
    expect(board.entries.last.isMe, isTrue);
    expect(board.divisionTitleFor(urdu: true), 'کانسی');
  });
}
