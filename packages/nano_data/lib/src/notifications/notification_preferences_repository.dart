import 'package:nano_domain/nano_domain.dart';

/// NOT-02 notification preference store (quiet hours / mute / digest).
abstract class NotificationPreferencesRepository {
  Future<NotificationPreferences> load({required String userId});

  Future<NotificationPreferences> save({
    required String userId,
    required NotificationPreferences preferences,
  });
}

class FakeNotificationPreferencesRepository
    implements NotificationPreferencesRepository {
  FakeNotificationPreferencesRepository({
    NotificationPreferences? seed,
    this.alwaysFail = false,
  }) : _prefs = seed ?? NotificationPreferences.defaults;

  NotificationPreferences _prefs;
  bool alwaysFail;

  @override
  Future<NotificationPreferences> load({required String userId}) async {
    if (alwaysFail) throw StateError('Preferences unavailable');
    return _prefs;
  }

  @override
  Future<NotificationPreferences> save({
    required String userId,
    required NotificationPreferences preferences,
  }) async {
    if (alwaysFail) throw StateError('Preferences save failed');
    // Drop illegal mutes for mandatory categories.
    final cleaned = {
      for (final category in preferences.mutedCategories)
        if (NotificationPreferencePolicy.canMute(category)) category,
    };
    _prefs = preferences.copyWith(mutedCategories: cleaned);
    return _prefs;
  }
}
