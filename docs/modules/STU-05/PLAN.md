# STU-05 — Plan

1. Schema: `privacy_settings` (owner-only RLS) and `public.revoke_device_session` (security definer, audited).
2. Domain: owner profile view, public projection that strips forbidden fields, privacy settings, richer `DeviceSession`.
3. Data: repository with privacy upsert and RPC revoke; fake covering failure and eligibility.
4. Design system: initials `NanoAvatar` (no uploaded photos yet).
5. Presentation: `StudentProfilePage` with privacy, settings, devices, and sign-out that clears sync caches.
6. Wiring: app holds a shared `NanoSyncController` and `StudentProfileRepository`; router passes them into the profile tab.
7. Adversarial SQL + domain/data/widget tests.
8. Docs and status.

## Reuse

- `student_preferences` and `AccessibilitySettingsPage` (STU-02 / FND-07)
- `device_sessions` and `login_events` (SEC-03)
- `LocalCacheStore` / `SyncQueueStore` / `NanoSyncController` (SYNC-01)
- `LevelProgress` (STU-04)
- `nano_internal.is_student` / `profile_is_active` (SEC-02 / STU-01)
