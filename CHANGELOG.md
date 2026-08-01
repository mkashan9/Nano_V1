# CHANGELOG

## Unreleased

- MED-06: Fish Audio narration and composed reaction clips — Fish is the default voice (MP3, stock until a reference_id is picked), json2video is the default video provider and animates only companion art a reviewer has already approved, a closed motion set replaces free-form generative prompts, unapproved or wrong-shaped art is refused before any money is spent, and a missing key still fails closed so every caption and every local reaction keeps working

- MED-06: art a person supplied — the only image model Nano can reach without buying one cannot draw a mascot, so rather than lower the gate a curator may now place a picture in the bucket and register it, with rights required and provenance recorded; curated art enters `ready` and `unreviewed` exactly like generated art, stays unreadable by every learner until a reviewer approves it, and a file nobody registered is unreachable by anyone

- MED-06: a reviewer can finally play what they are judging — the Moderation queue hands an MP3 or an MP4 to the browser's own player instead of showing a checksum and calling it a review, admin_web being the one app that never leaves the web; the student and teacher apps gain no player and no dependency, and a preview that will not load still leaves Reject working

- MED-06: a composed clip remembers what it was made of — the ask stamps the approved picture and the authored motion onto the asset, and the recorder merges provenance without letting a worker's nulls erase them; the first live render exposed the gap and the second landing carries both facts

- MED-05: publication as a superadmin decision — a review queue that shows the reviewer the prompt, provider, cost, and file that a learner never sees, approval as the only thing that makes generated media visible, rejection that un-publishes from catalog and storage in the same statement and frees the slot for a better attempt, an append-only record of who decided what and when, and refusals with reasons for everyone else

- MED-04: reusable reaction clip library — authored silent clips keyed by mode+mood, async Veo generation with recoverable claims, per-slot availability so one clip does not promise every mood, and a caption-safe companion play badge that only appears when a matching approved clip and a player both exist

- MED-03: Aoede Learning Guide voice — authored bilingual narration lines with immutable publish, a voice registry and voice-aware reuse hash, Gemini TTS adapter that wraps PCM as WAV, and a caption-first companion path where Listen appears only when a matching recording exists and sound is allowed (no player attached yet, so every line stays a caption)

- MED-02: generation budgets that refuse before a provider is reached — per-day platform, feature, and school limits with reuse deliberately charged nothing, real cost charged once when the provider reports it, approved files delivered through cacheable signed URLs while unapproved ones stay invisible, and a client catalog cache that asks rarely, keeps its last good answer, and lets a learner's screen look identical whether a clip exists, is refused, or the network is gone

- MED-01: server-side generated asset pipeline — a provider registry the database owns, hash-deduplicated requests that only a superadmin can make, single-flight claims and worker-only results, the first Edge Function with keyless image generation and key-holding voice/video adapters, and a client path that sees approved files with no prompt, provider, or cost

- CMP-03: Nori placed on the real learner screens at Junior and Senior density from one placement table, owned by a single session controller so cooldowns and the appearance budget survive navigation, only the surface in front speaks, and a held-back reaction costs no layout height

- CMP-02: controlled Nori variants (guide, explorer, quiz coach, builder, celebration) inside one shared frame, plus reaction rules — story cards for rare moments, priority for colliding moments, a per-session appearance budget, and Classroom Mode holding back everything non-essential

- CMP-01: a deterministic local Nori runtime — six core reactions, junior/senior density, cooldowns, captions that survive muted sound and Classroom Mode, and an asset ladder that never needs the network

- QZ-06: quiz results with per-question review and explanations released only after submit, a server-enforced retake budget, and recommendations that keep an unpassed quiz as review work

- QZ-05: trusted quiz attempts with resume, retake limits, and idempotent server scoring

- QZ-04: Senior quiz navigation and review without client-side scoring

- QZ-03: Junior one-question-per-screen quiz with companion prompts and no client-side score

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
