import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  group('XpBalance', () {
    test('parses the server balance payload', () {
      final balance = XpBalance.fromJson({
        'total': 40,
        'today': 10,
        'daily_cap': 200,
        'remaining_today': 190,
      });
      expect(balance.total, 40);
      expect(balance.remainingToday, 190);
    });

    test('missing fields read as zero rather than null', () {
      final balance = XpBalance.fromJson({});
      expect(balance.total, 0);
      expect(balance.dailyCap, 200);
    });
  });

  group('XpLedgerEntry', () {
    test('a credit and a debit are distinct', () {
      final credit = XpLedgerEntry.fromRow({
        'id': 'e1',
        'user_id': 'u1',
        'amount': 10,
        'source_kind': 'video_completion',
        'source_id': 'tv-1',
        'reason': '',
        'awarded_at': '2026-08-02T00:00:00Z',
      });
      final debit = XpLedgerEntry.fromRow({
        'id': 'e2',
        'user_id': 'u1',
        'amount': -10,
        'source_kind': 'reversal',
        'source_id': 'rev-1',
        'reason': 'mistaken award',
        'awarded_at': '2026-08-02T01:00:00Z',
      });
      expect(credit.isCredit, isTrue);
      expect(debit.isDebit, isTrue);
      expect(credit.sourceKind, XpSourceKind.videoCompletion);
    });
  });

  group('LevelProgress still derives from server XP', () {
    test('40 XP is still level 1 until XP-02 owns thresholds', () {
      final level = LevelProgress.fromXp(40);
      expect(level.level, 1);
      expect(level.xpIntoLevel, 40);
    });
  });
}
