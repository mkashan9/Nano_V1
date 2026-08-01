import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  group('LevelProgress.fromXp', () {
    test('560 XP is level 3 with 60 into the band', () {
      final progress = LevelProgress.fromXp(560);
      expect(progress.level, 3);
      expect(progress.xpIntoLevel, 60);
      expect(progress.xpToNextLevel, 190);
      expect(progress.fraction, closeTo(0.24, 0.001));
    });

    test('level never drops below one', () {
      expect(LevelProgress.fromXp(0).level, 1);
      expect(LevelProgress.fromXp(-50).level, 1);
      expect(LevelProgress.fromXp(-50).xpIntoLevel, 0);
    });
  });

  group('LevelProgress.fromServer', () {
    test('trusts the server fields even when they diverge from flat 250', () {
      // Non-linear example: level 5 starts at 900, next at 1200.
      final progress = LevelProgress.fromServer(
        level: 5,
        xpIntoLevel: 50,
        xpToNext: 250,
        xpPerLevel: 300,
      );
      expect(progress.level, 5);
      expect(progress.xpPerLevel, 300);
      expect(progress.xpToNextLevel, 250);
      expect(progress.fraction, closeTo(50 / 300, 0.001));
    });

    test('a max-level band with nothing left reports full progress', () {
      final progress = LevelProgress.fromServer(
        level: 40,
        xpIntoLevel: 10,
        xpToNext: 0,
        xpPerLevel: 10,
      );
      expect(progress.fraction, 1);
    });
  });

  group('XpBalance level fields', () {
    test('parses the XP-02 balance payload', () {
      final balance = XpBalance.fromJson({
        'total': 560,
        'today': 40,
        'daily_cap': 200,
        'remaining_today': 160,
        'level': 3,
        'xp_into_level': 60,
        'xp_to_next': 190,
        'xp_per_level': 250,
        'reconciled': true,
      });
      expect(balance.levelProgress.level, 3);
      expect(balance.levelProgress.xpIntoLevel, 60);
      expect(balance.reconciled, isTrue);
    });

    test('falls back to fromXp when level fields are absent', () {
      final balance = XpBalance.fromJson({
        'total': 560,
        'today': 0,
        'daily_cap': 200,
        'remaining_today': 200,
      });
      expect(balance.level, 3);
      expect(balance.xpIntoLevel, 60);
    });
  });
}
