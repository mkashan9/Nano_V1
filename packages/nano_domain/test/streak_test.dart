import 'package:flutter_test/flutter_test.dart';
import 'package:nano_domain/nano_domain.dart';

void main() {
  test('parses an active streak payload', () {
    final streak = StreakSnapshot.fromJson({
      'current': 3,
      'longest': 7,
      'last_active_on': '2026-08-02',
      'status': 'active',
      'notice': null,
      'message_en': '',
      'message_ur': '',
    });
    expect(streak.current, 3);
    expect(streak.longest, 7);
    expect(streak.status, StreakStatus.active);
    expect(streak.hasGentleNotice, isFalse);
  });

  test('welcome_back carries gentle copy', () {
    final streak = StreakSnapshot.fromJson({
      'current': 1,
      'longest': 5,
      'last_active_on': '2026-08-02',
      'status': 'active',
      'notice': 'welcome_back',
      'message_en': 'Welcome back.',
      'message_ur': 'خوش آمدید۔',
    });
    expect(streak.hasGentleNotice, isTrue);
    expect(streak.messageFor(urdu: false), 'Welcome back.');
  });
}
