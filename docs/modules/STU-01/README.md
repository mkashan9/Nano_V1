# STU-01 — Student First-Run Onboarding

## Purpose

Introduce Nano on first launch, resolve the Junior or Senior experience, and frame the learner's context (school-linked or independent) without ever promising features they cannot use.

## Deliverables

- `public.student_onboarding` progress table with per-learner RLS and a students-only write guard
- `OnboardingStep`, `ExperienceTrack`, `ExperiencePolicy`, `OnboardingProgress` domain models
- `OnboardingRepository` with fake and Supabase implementations
- Student app `/onboarding` route gated after sign-in, resuming at the saved step
- Bilingual onboarding copy (English and Urdu)

## Owner test focus

Sign in as a new learner, walk the flow, close the tab mid-flow and reopen to confirm it resumes, and check that an independent learner sees no school promises.
