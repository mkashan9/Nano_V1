# STU-05 — Student Profile and Settings

## Purpose

Give every learner an owner-safe place to see who they are, how they are doing, control who can see them, manage devices, and sign out. The profile screen is the owner's view; anything that leaves this screen goes through `PublicProfileProjection`, which strips private academic and contact data.

## Deliverables

- `public.privacy_settings` with owner-only RLS (discoverable, show achievements, allow friend requests)
- `public.revoke_device_session(uuid)` — the first client-callable RPC; owner-only, audited to `login_events`, never touches another user's session
- Domain: `StudentProfileView`, `PublicProfileProjection`, `PrivacySettings`, extended `DeviceSession`
- Data: `StudentProfileRepository` (fake + Supabase) with privacy upsert and RPC revoke
- Design system: `NanoAvatar` initials avatar
- `StudentProfilePage` replacing the profile placeholder: identity, progress, achievements, privacy toggles, language, accessibility entry, devices with revoke, sign-out
- Sign-out clears `LocalCacheStore` and `SyncQueueStore` before ending the session

## Owner test focus

Open Profile, toggle "Let others find me" off, confirm it stays after a reload, revoke the non-current device, then sign out and confirm the next learner does not inherit language or drafts.
