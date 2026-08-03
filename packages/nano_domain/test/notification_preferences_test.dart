import 'package:nano_domain/nano_domain.dart';
import 'package:test/test.dart';

void main() {
  test('mandatory categories cannot be muted', () {
    expect(NotificationPreferencePolicy.canMute('account'), isFalse);
    expect(NotificationPreferencePolicy.canMute('security'), isFalse);
    expect(NotificationPreferencePolicy.canMute('learning'), isTrue);
  });

  test('quiet hours wrap midnight', () {
    const prefs = NotificationPreferences(
      quietHoursEnabled: true,
      quietStartHour: 21,
      quietEndHour: 7,
    );
    expect(
      NotificationPreferencePolicy.isInQuietHours(
        prefs,
        DateTime(2026, 8, 3, 22),
      ),
      isTrue,
    );
    expect(
      NotificationPreferencePolicy.isInQuietHours(
        prefs,
        DateTime(2026, 8, 3, 6),
      ),
      isTrue,
    );
    expect(
      NotificationPreferencePolicy.isInQuietHours(
        prefs,
        DateTime(2026, 8, 3, 10),
      ),
      isFalse,
    );
  });

  test('decide suppresses mute and holds for digest in quiet hours', () {
    final prefs = NotificationPreferences.defaults.copyWith(
      quietHoursEnabled: true,
      digestEnabled: true,
      mutedCategories: {'learning'},
    );
    expect(
      NotificationPreferencePolicy.decide(
        prefs: prefs,
        category: 'learning',
        localNow: DateTime(2026, 8, 3, 10),
      ).action,
      NotificationDeliveryAction.suppressMuted,
    );
    expect(
      NotificationPreferencePolicy.decide(
        prefs: prefs.copyWith(mutedCategories: {}),
        category: 'school',
        localNow: DateTime(2026, 8, 3, 22),
      ).action,
      NotificationDeliveryAction.holdForDigest,
    );
    expect(
      NotificationPreferencePolicy.decide(
        prefs: prefs,
        category: 'account',
        localNow: DateTime(2026, 8, 3, 22),
      ).action,
      NotificationDeliveryAction.deliverNow,
    );
  });
}
