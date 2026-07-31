# STU-02 — Nori Naming, Language, Sound, and Accessibility Setup

## Purpose

Let each learner name their learning guide, pick English or Urdu, and set sound, captions, and reduced-motion preferences during first-run setup. Defaults are safe locally; saved values sync to the server.

## Deliverables

- `public.student_preferences` with owner-only RLS (no staff or platform read path)
- `CompanionNamePolicy`, `StudentPreferences` domain models
- `StudentPreferencesRepository` (fake + Supabase)
- New `preferences` onboarding step between experience and context
- Live application of locale and accessibility during the flow
- Bilingual setup copy

## Owner test focus

Name the companion something other than Nori, switch to Urdu mid-flow, confirm the UI flips RTL, finish onboarding, reload, and confirm the saved name and language stick.
