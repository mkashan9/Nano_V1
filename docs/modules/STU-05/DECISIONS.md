# STU-05 — Decisions

1. **Owner view vs public projection.** `StudentProfileView` holds private fields (email, guardian, attendance, marks). `PublicProfileProjection.of` builds the only shape a social surface may see, and `forbiddenFields` is a testable list so the rule cannot silently regress.
2. **First client-callable RPC lives in `public`.** SEC-02 kept helpers in `nano_internal` so they stay off `/rest/v1/rpc`. Device sessions have no client write policy, so revoke needs a function. Putting it in `public` is intentional and documented; it still only updates `auth.uid()`'s own active row and writes a `login_events.revoke` audit. The Supabase advisor warning about authenticated EXECUTE on a SECURITY DEFINER function is accepted for this path.
3. **Direct table writes stay denied.** Adversarial tests prove a plain `UPDATE device_sessions` fails; only the RPC can revoke.
4. **Current device is not revocable from the list.** Revoking the device you are holding would look like a silent sign-out of "someone else". The current session is labelled and the list's revoke action is reserved for other devices; full sign-out is a separate button.
5. **Sign-out clears caches first.** Handbook PRF-01: "Logout clears private local caches." The sync cache and queue are cleared before the auth call so a network failure still leaves nothing for the next person on the device. Locale and accessibility also reset to defaults.
6. **No uploaded avatars yet.** `NanoAvatar` shows initials. Uploaded photos and social faces wait for media and SAFE modules.
7. **Progress and achievements are fixture-backed.** LRN/XP/NOT own the real read models; the profile screen is ready for them via the repository.
8. **Junior sensitive-settings guardian gate is deferred.** Accessibility and language are already learner-editable (STU-02). A guardian PIN for destructive privacy changes lands with SAFE/PRF expansion; this module keeps the toggles simple and owner-owned.
