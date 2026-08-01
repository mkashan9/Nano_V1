# CHANGELOG

## Unreleased

- QZ-02: topic-attached ordered quiz versions with immutable publish, learner-safe projection, and Junior/Senior curator preview

- QZ-01: platform-admin question bank with immutable published versions, duplicate-stem warnings, and Junior/Senior curator preview

- LRN-05: per-subject progress summary and server-ranked next-up recommendations that can only name topics the learner may already open

- LRN-04: long-video refresh checkpoints at safe chapter boundaries, a server-enforced required-checkpoint credit gate, and content-configured seeking

- LRN-03: server-credited watch time, resume, captions, and audited one-time topic completion

- LRN-02: topic ordering invariants, prerequisite write gates, RPC-only progress, and topic detail with unlock reason

- Fix: onboarding steps commit even when saving settings rebuilds the app, and a failed save now says so

- LRN-01: learning catalog with publication model, eligibility, prerequisite locks, Junior worlds / Senior search, and shared version IDs

- STU-05: student profile with privacy settings, audited device revoke, and sign-out that clears private caches

- STU-04: senior home with level and XP progress, Today's Plan, eligibility-gated Flex summary, and partial-data section notices

- STU-03: junior home with aggregated home summary, repository-backed content, and full state coverage

- STU-02: companion naming, language, sound, and accessibility preferences with owner-only RLS

- STU-01: student first-run onboarding with resumable server-side progress and grade-derived experience track

- AUTH-04: independent student signup via auth.users trigger, password recovery, profiles↔auth.users cascade

- AUTH-03: admin_web sign-in for school admin + platform superadmin fixtures

- AUTH-02: teacher sign-in, Ms Khan auth.users fixture, app-scoped account kinds

- AUTH-01: student sign-in, Ali auth.users fixture, nano_auth session bootstrap

- SYNC-01: local cache/queue substrate, conflict banner, Offline debug preview, ADR-0007

- SEC-03: audit/session tables, suspension-aware RLS helpers, AccessGuard domain models

- SEC-02: multi-school tenancy tables, RLS, nano_internal helpers, Alpha/Beta fixtures

- SEC-01: remote-first Supabase baseline, app_health, migration workflow

- FND-07: accessibility prefs, feedback gates, reduced motion, A11y settings

- FND-06: English/Urdu NanoCopy, RTL locale wiring, locale preview

- FND-05: shared NanoViewState, state host, maintenance/permission/sync chrome

- FND-04: role-aware shells, go_router, deep-link fallback, Flex eligibility

### Added

- FND-03: Junior/Senior responsive home foundations, preview widths, shared fixtures


### Added

- FND-02: design tokens, Junior/Senior/Teacher/Admin themes, core components, goldens, gallery


### Added

- FND-01: Melos/Dart workspace, student/teacher/admin apps, shared packages, remote-first env docs
- AUD-01 closeout: removed avatar_trials; ADR-0002 no Docker


### Added

- Bootstrap: credential migration, ignore rules, handbook extraction, UI catalog
- Automation controls: module queue, status docs, Cursor rules
- AUD-01 audit documentation set
