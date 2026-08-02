import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('LeagueStatus parses join and rank fields', () {
    final status = LeagueStatus.fromJson({
      'joined': true,
      'week_key': '2026-W31',
      'starts_at': '2026-07-27T00:00:00Z',
      'ends_at': '2026-08-03T00:00:00Z',
      'status': 'open',
      'week_xp': 60,
      'rank': 3,
      'peer_count': 12,
      'division_slug': 'bronze',
      'division_title_en': 'Bronze',
      'division_title_ur': 'کانسی',
    });
    expect(status.joined, isTrue);
    expect(status.weekXp, 60);
    expect(status.rank, 3);
    expect(status.divisionTitleFor(urdu: true), 'کانسی');
    expect(status.isOpen, isTrue);
  });
}
