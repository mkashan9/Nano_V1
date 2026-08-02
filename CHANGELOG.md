# CHANGELOG

## Unreleased

- GME-01: students browse eligible published games (no play host yet)
- FBK-01: teachers draft and publish structured feedback for roster students
- FLX-04: students read published classroom announcements and acknowledge
- FLX-03: students view their own published marks by month
- FLX-02: students view their own submitted attendance by month
- FLX-01: school-linked Flex hub (attendance / marks / classroom entry cards)
- CLS-03: schedule/expiry on drafts; acknowledgement counts for teachers
- CLS-02: teachers attach https links to draft classroom announcements
- CLS-01: teachers create draft classroom announcements for assigned scopes
- MRK-05: teachers see class performance summaries for published assessments
- MRK-04: teachers publish draft marks and correct published entries with immutable history
- MRK-03: teachers download/preview/commit marks CSV templates into draft marks grids
- MRK-02: teachers enter draft marks grids for draft assessments with status and caps
- MRK-01: teachers create and edit draft assessments for assigned scopes
- ATT-03: teachers correct submitted attendance with required reason and immutable history
- ATT-02: teachers download/preview/commit attendance CSV templates into canonical sessions
- ATT-01: teachers submit in-app attendance grids for assigned scopes with idempotent submit
- TCH-02: teachers open My Classes for assignment-scoped rosters with server guards
- TCH-01: teachers open Dashboard for caller-scoped assignments and pending workflow stubs
- SCH-07: school admins open Reports for privacy-safe coverage, enrollment, and workload summaries
- SCH-06: school admins configure marks/result policies and result periods in Settings
- SCH-05: school admins assign teachers to class/section/subject with coverage and workload
- SCH-04: school admins manage students (create, suspend, enroll) and CSV import from Students
- SCH-03: school admins manage teachers (create, suspend) and CSV import from Teachers
- SCH-02: school admins manage grades, classes, sections, and school subjects from Classes
- SCH-01: school admins get Overview metrics/setup progress and Settings branding edits
- ADM-08: platform staff can open Analytics for privacy-safe health, catalog, and 7-day activity aggregates
- ADM-07: platform staff can draft, publish, and disable notification templates from Notifications
- ADM-06: platform staff can draft, publish, and disable game catalog versions from Games
- ADM-05: platform staff can edit XP policy/levels, toggle achievements and missions, and adjust XP with a reason
- ADM-04: platform staff can draft, publish, and archive Learning Stack subjects/topics from Content ? Catalog
- ADM-03: platform staff can search users safely, suspend/restore with reason, replace school admin, and revoke sessions
- ADM-02: platform staff can create schools with immutable codes, change status with an audited reason, and assign the first school admin

- ADM-01: superadmin Platform home with safe metrics, school directory search, and audit preview; Content/Moderation stay on the existing shell

- XP-06: privacy-safe achievement and quiz score share cards (clipboard), plus featured pins (max 3) on Me; school records stay off the card

- XP-05: streaks are consecutive learning days, not a fixture ? topic complete and quiz pass extend a UTC-day streak once, a gap pauses it with welcome-back copy instead of blame, and Home/Me read my_streak when Supabase is wired

- XP-04: Home's plan is finally real missions ? daily lesson/quiz and weekly lesson/quiz targets track period progress, award bonus XP once through the ledger, and replace the fixture trio when Supabase is wired

- XP-03: Me shows real badges and stickers ? First Steps, Quiz Rookie, Rising Star, and Level Climber unlock from topic completions, quiz passes, and level bands, unique so a replay cannot grant twice, and stickers are a kind on the same catalog rather than a second grant path

- XP-02: levels left the client ? `level_rules` owns the curve (flat 250 XP through level 40 at seed), `xp_progress` stays in lockstep with every ledger award, and `my_xp_balance` now returns the level Home and Me already draw, so a threshold change is a data change rather than an app release

- XP-01: XP is finally a ledger, not a fixture ? video completion and quiz pass credit the same append-only table, keyed so a replay cannot award twice, capped so a busy day cannot print money, and readable on Home and Me when Supabase is wired; failed quizzes still award nothing, and levels stay display-only until XP-02

- MED-12: Nori is present on every product surface the placement policy names ? onboarding and quiz results left the throwaway runtimes that made a celebration never count against the session budget and a greeting after onboarding fire twice; both now go through the shared controller, quiz questions carry coaching instead of a blank slot, and error/empty/offline may show Nori above the chrome without ever covering the button you need to press

- MED-12: coverage became a build gate rather than a checklist ? `CompanionCoverage` derives the reachable matrix from the enums so adding a surface or an event is enough to fail the build, student tests fail when a product surface does not mount the session companion, and Moderation shows which celebration clip slots still have no approved art so a complete review queue can no longer hide an incomplete companion

- MED-11: Nori can be heard everywhere it can be seen ? MED-03 built narration and MED-06 cast the voice, but exactly one line had ever been recorded, so a companion that appeared on every surface spoke on one of them; every published non-personalised line is now recorded in English and in Urdu in the cast guide voice, sixteen recordings for 7,536 micros, which is under a cent and less than the two rejected clip attempts from MED-06 cost

- MED-11: the personalised greeting stays silent on purpose and a test enforces it ? a recording of "Hello, {name}" would say one child's companion name to every other child, so ADR-0008 makes those lines caption-only, and the coverage probe now fails if a personalised line ever acquires an approved recording by some future convenience

- MED-11: coverage became an invariant rather than a fact ? it is the kind of property that is true on the day it ships and quietly false six modules later, so the reachable set is derived from `CompanionEvent.values` instead of listed, and a separate assertion catches the case that looks fine from outside: a mood whose only line is personalised is permanently mute however much narration gets generated

- MED-11: the Urdu recordings were generated rather than reasoned about ? the voice is a clone cast against English lines and nothing verified it against Urdu script, so fifteen files of evidence a person can listen to beat a paragraph of speculation; rejecting the whole Urdu set costs nothing because strict locale match already degrades a missing recording to its caption, and one probe now checks from the database side that no audio file is ever shared across two locales

- MED-11: the celebration clips waited for the gate rather than going around it ? a clip composes from an approved image and the celebration art had only existed bundled, so the choice was to approve it on the owner's behalf, bypass the ladder, or register it and stop; an agent that approves its own output to unblock itself has removed the MED-05 gate rather than passed it, so the art was queued, the owner decided it, and all five celebration modes rendered on Wan for nothing in the same session

- MED-11: the clip library refused to be extended over the wire and that turned out to be the design working ? three of the five celebration modes did not exist as reactions and `create_reaction_clip_draft` raises on an unknown slug, so which moments deserve a clip at all stays a product decision living in git and in review rather than something a script can conjure; guide, explorer, and builder arrived by migration

- MED-11: the default mode's celebration was rendered twice, and the second time on purpose ? the first came back from the json2video fallback because it fired while the Wan attempt was still generating, which errored nowhere and looked like fine metadata in a table, except guide is the mode most learners actually reach, json2video is the provider whose output was rejected twice in MED-06 for looking fake, and it costs 15,000 micros against Wan's zero; a probe now fails on any approved clip from the fallback, because the expensive ugly one slipping through unnoticed is precisely the failure that does not announce itself

- MED-10: Nori breathes ? a drawing that holds perfectly still reads as broken rather than calm, and `CompanionAssetTier.localAnimation` had been mapped to the greeting mood since CMP-01 with nothing implementing it, so it silently resolved down to static art; each of the six moods now carries its own breath, drift, and tilt, applied as arithmetic over art that already shipped, so the tier that makes a companion feel alive is also the only one that costs nothing to run

- MED-10: motion is capped, framed, and free ? nothing moves more than four percent and most under two, because a companion that moves enough to notice is competing with the lesson, and a test asserts the ceiling so a later "make it livelier" tweak cannot quietly raise it; the transform sits inside the circular mask so the ring and the play badge never move under a learner's finger, and the ticker comes from `TickerMode` so an off-screen or backgrounded companion burns nothing

- MED-10: reduced motion and Classroom Mode stop it dead, not slow it down ? the gate is `NanoMotion.resolve`, the single place both preferences and the platform's own setting are read, so no tier table can outvote a child's choice; the controller is stopped rather than merely ignored, and the drawing stays, because reduced motion is a request for calm rather than for less companion

- MED-10: gentle retry is the one mood with no tilt at all, asserted by a test rather than remembered ? a springy, waggling companion in front of a child who just got an answer wrong is the worst thing this tier could do, and it is exactly the kind of thing that arrives later as a one-line tweak

- MED-09: Nori is a drawing everywhere instead of an icon ? one approved picture existed and the other 24 reachable reactions fell back to a Material glyph in a circle, which mattered more than it sounds because reduced motion collapses every tier down to static art, so the floor under the whole companion was a placeholder; the app now ships a pose for each of the six moods, 135 KB for the set, beneath the published rung and above the icon, so the icon is unreachable without a corrupt install and a learner in airplane mode still has a companion

- MED-09: six drawings cover twenty-five slots because a mode is a ring, not a character ? CMP-02 defines Guide, Explorer, Quiz Coach, Builder, and Celebration as the same Nori with a different accent and framing, and the stage already draws both around the art, so one pose per mood renders every pair and the four modes cannot drift apart; generating four variants of each pose would have multiplied the exact failure this module exists to prevent, and the per-slot published path stays open for a curator who genuinely wants a different one

- MED-09: the canonical Nori is recorded rather than remembered ? character drift is what happens when a mascot is generated one pose at a time and each image is plausible alone, so `companion_character_sheet` holds a versioned, locked description with one current row, naming the approved picture every pose was reference-conditioned on; it lives in the database as well as the repository because the reviewer who needs it is in admin_web and cannot read a markdown file while deciding

- Fix: approved companion art reaches a learner after sign-in ? the app used to ask for the published catalog before anyone was authenticated, cache the anonymous failure as an empty answer for six hours, and never ask again, so a reviewer-approved Nori stayed invisible while the icon and caption still rendered; catalogs now load only with a live session, and a failed fetch no longer locks the TTL

- Fix: a learner's experience follows the track they chose, not the account kind they signed up with ? onboarding recorded junior or senior in `student_onboarding`, sign-in reads `profiles` and never saw it, and the app loaded the track on every launch and then dropped it, applying it only in the session where onboarding happened to finish; a returning Junior was handed the Senior experience, which is quiet on home, so the companion never appeared at all. `SessionPrincipal` now carries the track and presentation follows it, because an independent learner keeps one role at every age and a role alone cannot tell a six-year-old from a sixteen-year-old

- MED-08: the media finally reaches a child ? seven modules generated, budgeted, reviewed, published, and delivered companion assets that nothing on screen could display, so Nori was a paw icon and the Listen and Play controls could never appear; the app now draws the approved picture, plays the recording in the voice that was cast, and plays the Wan clip silently, and every failure below that ? an expired URL, a dead link, a codec that will not open, no plugin at all ? falls to a picture or an icon and a caption rather than an error or an empty frame

- MED-08: a published clip may lift a mood one rung and no further ? the tier map is the floor the app reaches offline, so a mood that already animates locally can become a clip while routine moods stay still art however much is published, which is what made the approved greeting clip reachable at all and what keeps video off ordinary moments

- MED-08: lesson playback is real where there is anything to play ? a topic whose reference parses as a URL is decoded, resume, seek clamping, checkpoints, heartbeats, and completion all run from the frames actually shown, and the deterministic one-second clock stays for the `fixture` topics that are the entire catalog today, because watch credit should be provable without a codec

- MED-07: character animation instead of a camera pan ? Wan 2.2 image-to-video is the default clip provider, animates approved Nori art rather than inventing it, falls back in one hop to json2video when the public Space is unusable, records the swap so a reviewer sees who actually made the file, and holds the connection for the whole render because the Space is not resumable

- MED-06: Fish Audio narration and composed reaction clips ? Fish is the default voice (MP3, stock until a reference_id is picked), json2video is the default video provider and animates only companion art a reviewer has already approved, a closed motion set replaces free-form generative prompts, unapproved or wrong-shaped art is refused before any money is spent, and a missing key still fails closed so every caption and every local reaction keeps working

- MED-06: art a person supplied ? the only image model Nano can reach without buying one cannot draw a mascot, so rather than lower the gate a curator may now place a picture in the bucket and register it, with rights required and provenance recorded; curated art enters `ready` and `unreviewed` exactly like generated art, stays unreadable by every learner until a reviewer approves it, and a file nobody registered is unreachable by anyone

- MED-06: the Learning Guide is cast ? Fish Educational Guide (`guide_educational`, ADR-0008) is the default voice, a female teacher register rather than the mascot speaking; stock stays reachable but is no longer default, and the stock recording of `greeting-2` was rejected and re-recorded before the module left USER_TEST

- MED-06: a reviewer can finally play what they are judging ? the Moderation queue hands an MP3 or an MP4 to the browser's own player instead of showing a checksum and calling it a review, admin_web being the one app that never leaves the web; the student and teacher apps gain no player and no dependency, and a preview that will not load still leaves Reject working

- MED-06: a composed clip remembers what it was made of ? the ask stamps the approved picture and the authored motion onto the asset, and the recorder merges provenance without letting a worker's nulls erase them; the first live render exposed the gap and the second landing carries both facts

- MED-05: publication as a superadmin decision ? a review queue that shows the reviewer the prompt, provider, cost, and file that a learner never sees, approval as the only thing that makes generated media visible, rejection that un-publishes from catalog and storage in the same statement and frees the slot for a better attempt, an append-only record of who decided what and when, and refusals with reasons for everyone else

- MED-04: reusable reaction clip library ? authored silent clips keyed by mode+mood, async Veo generation with recoverable claims, per-slot availability so one clip does not promise every mood, and a caption-safe companion play badge that only appears when a matching approved clip and a player both exist

- MED-03: Aoede Learning Guide voice ? authored bilingual narration lines with immutable publish, a voice registry and voice-aware reuse hash, Gemini TTS adapter that wraps PCM as WAV, and a caption-first companion path where Listen appears only when a matching recording exists and sound is allowed (no player attached yet, so every line stays a caption)

- MED-02: generation budgets that refuse before a provider is reached ? per-day platform, feature, and school limits with reuse deliberately charged nothing, real cost charged once when the provider reports it, approved files delivered through cacheable signed URLs while unapproved ones stay invisible, and a client catalog cache that asks rarely, keeps its last good answer, and lets a learner's screen look identical whether a clip exists, is refused, or the network is gone

- MED-01: server-side generated asset pipeline ? a provider registry the database owns, hash-deduplicated requests that only a superadmin can make, single-flight claims and worker-only results, the first Edge Function with keyless image generation and key-holding voice/video adapters, and a client path that sees approved files with no prompt, provider, or cost

- CMP-03: Nori placed on the real learner screens at Junior and Senior density from one placement table, owned by a single session controller so cooldowns and the appearance budget survive navigation, only the surface in front speaks, and a held-back reaction costs no layout height

- CMP-02: controlled Nori variants (guide, explorer, quiz coach, builder, celebration) inside one shared frame, plus reaction rules ? story cards for rare moments, priority for colliding moments, a per-session appearance budget, and Classroom Mode holding back everything non-essential

- CMP-01: a deterministic local Nori runtime ? six core reactions, junior/senior density, cooldowns, captions that survive muted sound and Classroom Mode, and an asset ladder that never needs the network

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

- AUTH-04: independent student signup via auth.users trigger, password recovery, profiles?auth.users cascade

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
