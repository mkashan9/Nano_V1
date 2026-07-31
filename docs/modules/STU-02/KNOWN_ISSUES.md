# STU-02 Known Issues

- Fixed during USER_TEST: `/onboarding` was handed to DeepLinkResolver, which
  does not know that gate path and fell back to `/`, causing a redirect loop
  with the onboarding guard. Gate paths are now excluded from deep-link fallback.
- Companion naming has no moderated word list yet; SAFE modules own that later.
- Haptics and Classroom Mode are not on the first-run step; they remain on the accessibility settings page.
- Preference writes are not queued offline; they require connectivity, matching AUTH offline rules.
- Existing learners who completed STU-01 before this module have no preferences row until they open settings or re-enter onboarding somehow; STU-05 should offer a replay path.
- The companion is still a placeholder slot; CMP-01 owns the real Nori runtime.
