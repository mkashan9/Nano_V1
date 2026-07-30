# Nano Product and Implementation Handbook

> Machine-readable extraction of `Nano_Product_and_Implementation_Handbook_v1.0.docx`.
> Do not edit the original DOCX; update this file only when re-extracting.

NANO

Product & Implementation Handbook

A modular blueprint for the Flutter mobile apps, Flutter Web portals, Supabase backend, companion system, games, safety, testing, and Cursor-led delivery.

| Document field | Value |
| --- | --- |
| Product | Nano |
| Version | 1.0 |
| Date | 30 July 2026 |
| Primary stack | Flutter mobile + Flutter Web + Supabase/Postgres |
| Architecture | Feature-first MVVM with repositories, services, and server-authoritative domain operations |
| Audience | Product owner, Cursor/AI coding agents, Flutter developers, backend developers, QA, designers, and school pilot team |

| Purpose of this handbook This is the build contract for Nano. It converts the product idea into modules, boundaries, dependencies, data ownership, release stages, testing gates, and rules that an AI coding workflow can follow without turning the project into one tightly coupled codebase. |
| --- |

# Document Status

What this version contains, what it decides, and what still requires repository access.

This handbook consolidates the complete Nano feature concept supplied by the product owner and converts it into an implementation sequence. It preserves the Junior and Senior student experiences, school-linked and independent accounts, teacher workflows, school management, platform administration, gamification, games, communities, and the Nori companion system.

| Local code limitation The Windows path C:\Users\0\Desktop\demo\demo1 was referenced in the source brief, but it was not accessible from this environment. Before implementation begins, copy that repository into the active workspace and run the Existing Code Audit described in Chapter 7. No claim is made here that the local code has already been reviewed. |
| --- |

Technical direction was checked against current official guidance from Flutter and Supabase. Flutter’s current architecture guidance supports MVVM-style Views and ViewModels with repositories and services in the data layer. Supabase requires Row Level Security on exposed tables, and privileged scoring or third-party integrations belong in database functions or authenticated Edge Functions rather than in the client.

## Status vocabulary

| Label | Meaning |
| --- | --- |
| Pilot | Required for the first usable school pilot. Must be stable, secure, and testable. |
| Post-pilot | Important product capability that follows after the pilot proves core academic workflows. |
| Safety-gated | Must not be released until moderation, privacy, reporting, and abuse controls are operational. |
| Future | Planned extension. Architecture must allow it, but the pilot must not depend on it. |
| Experiment | Prototype behind a feature flag. It may be removed without migration obligations. |

# Contents

| Chapter | Topic |
| --- | --- |
| 1 | Product Definition and Non-Negotiable Rules |
| 2 | Release Strategy and Scope Control |
| 3 | Experience Architecture: Junior, Senior, Teacher, and Web |
| 4 | Technical Architecture |
| 5 | Repository and Code Organization |
| 6 | Data, Security, Tenancy, and Server Authority |
| 7 | Reuse-First Engineering and Existing Code Audit |
| 8 | Design System and UI-First Workflow |
| 9 | Module Catalog |
| 10 | Companion, Voice, and Generated Media Strategy |
| 11 | Games Integration and Trusted XP |
| 12 | Offline, Sync, Notifications, and Media |
| 13 | Testing and Quality Gates |
| 14 | Cursor Operating Protocol |
| 15 | Implementation Roadmap |
| 16 | Deployment, Observability, and Operations |
| 17 | Risks, Decisions, and Change Control |
| Appendix A | Core Data Model |
| Appendix B | Permissions Matrix |
| Appendix C | Definition of Done |
| Appendix D | Feature Traceability |
| Appendix E | Reference Notes |

# 1. Product Definition and Non-Negotiable Rules

## 1.1 Product statement

Nano is a multi-school learning platform with a Flutter mobile application for students and teachers and a Flutter Web administration portal for school management and platform superadmins. The same backend serves every school, but each school’s records, users, academic structures, and private content remain isolated.

## 1.2 Product surfaces

| Surface | Users | Primary purpose |
| --- | --- | --- |
| Student mobile app | School-linked and independent students | Learning Stack, quizzes, games, progress, Flex for school-linked students, profile, notifications, and controlled social features. |
| Teacher mobile app | Teachers | Attendance, marks, Classroom content, class visibility, structured parent feedback, and teacher communities. |
| School management web portal | Principal and authorized school staff | School setup, users, classes, sections, subjects, assignments, results, imports, reports, and feature controls. |
| Platform superadmin web portal | Nano operations and content team | Schools, global users, Learning Stack publishing, quizzes, games, gamification, safety, notifications, audit, and analytics. |
| Guardian module | Linked parents or guardians | Weekly guidance and selected child information. This is a future controlled module, not a pilot dependency. |

## 1.3 Account and experience model

- School-linked student: Receives school identity and can access Flex, attendance, published marks, Classroom, school announcements, and school-scoped rankings where enabled.

- Independent student: Uses Learning Stack, quizzes, games, progress, profile, and allowed social areas. The interface simply omits school-only features. It must never display fake locks or empty Flex placeholders.

- Junior experience: Playgroup through Class 3. Large controls, short labels, audio support, fewer simultaneous choices, softer competition, and frequent companion guidance.

- Senior experience: Class 4 and above. More information density, search and filters, richer progress, communities, friends, challenges, and detailed records.

| One domain, two presentations Junior and Senior experiences do not create separate data models. They render the same domain records through different screen compositions, copy density, navigation depth, and interaction policies. This prevents duplicated business logic and inconsistent scores. |
| --- |

## 1.4 Non-negotiable product rules

- School marks, attendance, and report-card results never generate XP and never determine leaderboard position.

- Video completion may award a small amount of XP. Quiz performance and verified game performance may award more, within server-defined caps.

- The same trusted event cannot award XP twice. Every award has an immutable reason and source-event identifier.

- Draft marks remain invisible to students. Only published assessment versions are visible.

- Independent students do not see Flex, school announcements, school marks, or school attendance. The UI should feel complete rather than restricted.

- Communities are hidden from Junior students. Senior communities are safety-gated.

- The server decides identity, permissions, school status, assessment publication, quiz score, XP, rank, verified game score, and social eligibility.

- Every school-owned record contains or securely derives a school identifier, and every access path is checked by Row Level Security and server-side authorization.

- Every feature supports loading, empty, permission-denied, disabled, suspended, offline, syncing, failure, and retry states where applicable.

# 2. Release Strategy and Scope Control

Nano is too large to build safely as one release. The correct strategy is a thin vertical pilot first, followed by growth modules. UI may be produced early across the product, but production backend work must follow dependency order.

## 2.1 Release stages

| Stage | Goal | Included |
| --- | --- | --- |
| R0: Foundation and UI prototype | Make the project navigable and visually testable without production data. | Repository foundation, design tokens, navigation shells, mocked auth states, Junior and Senior reference screens, teacher and web shells, component catalog, fixture data. |
| R1: School pilot | Run one school through core academic and learning workflows. | Tenancy, auth, school setup, users, classes/sections/subjects, teacher assignments, attendance, marks publishing, Classroom, Learning Stack, video progress, quizzes, basic XP, notifications, audit, reports. |
| R2: Engagement | Add stronger motivation and content operations. | Games catalog and secure game bridge, achievements, stickers, missions, streaks, leagues, richer profile, shareable result cards, content analytics. |
| R3: Controlled social | Introduce social value only after safety systems pass. | Friends, challenges, Senior communities, moderation queue, blocking, reporting, media policy, school discovery rules. |
| R4: Expansion | Add commercial and family extensions. | Independent subscriptions, guardian portal, advanced analytics, broader integrations, more game types, recommendation systems. |

## 2.2 Pilot success criteria

- A school can be created, branded, and configured without database intervention.

- Students and teachers can sign in with school-created credentials and are correctly restricted to their school and assignment scope.

- A teacher can mark attendance on mobile, recover from a short interruption, submit once, and correct with a reason.

- A teacher can create an assessment, enter or import marks, save a draft, publish, and produce student-visible results.

- The superadmin can publish a subject, topic, video, and ordered quiz; a student can watch, resume, complete, submit, and receive a server-calculated score.

- XP is awarded once from approved events and can be audited.

- No user from School A can read or mutate School B data in automated RLS tests.

- Core flows work on a small Android phone, a typical tablet, and desktop web for administration.

## 2.3 Scope controls

- Every module has a feature flag and a release label.

- A module may expose mock repositories during UI work, but production status requires the real repository, RLS policies, migrations, tests, logging, and error states.

- No module may directly write another module’s tables. Cross-module mutations go through a domain service, database function, or event contract.

- A new request is added to the backlog and dependency map before code changes begin. Large additions do not enter a half-finished active module.

- Generated assets, third-party games, and open-source code must have provenance and license records before production use.

# 3. Experience Architecture: Junior, Senior, Teacher, and Web

## 3.1 Shared domain, separate shells

Use shared packages for domain models, repositories, permissions, analytics events, localization keys, and design tokens. Build separate app shells for student, teacher, and administration because their navigation, density, and risk profiles differ.

| Shell | Navigation approach | Design character |
| --- | --- | --- |
| Junior student | Bottom navigation with very few destinations and one dominant next action. | Illustration-led, large cards, rounded shapes, audio cues, short copy, calm competition. |
| Senior student | Bottom navigation with Learning, Games, Flex when eligible, Communities, and Profile. | More information, search, progress, social controls, still friendly and uncluttered. |
| Teacher mobile | Task-oriented bottom navigation or compact drawer: Dashboard, Classes, Attendance, Marks, Classroom, Profile. | Professional, fast, spreadsheet-like where needed, optimized for one-handed mobile entry. |
| School web | Persistent side navigation with role-based sections and bulk workflows. | Dense but readable tables, filters, import validation, audit history, responsive desktop-first layout. |
| Superadmin web | Persistent side navigation with stronger privileged-action boundaries. | Operational dashboard, content workflows, version history, moderation, analytics, and explicit confirmations. |

## 3.2 Junior interaction rules

- Show two to four primary choices at a time.

- Prefer recognition over recall: pictures, icons, familiar colors, and spoken prompts.

- Use one primary action per card and avoid long forms.

- Never show technical terms such as sync queue, asset version, download manifest, or failed verification.

- Competition emphasizes participation and personal improvement. Do not show humiliating rank-loss copy.

- Sensitive settings require a guardian gate or school-controlled policy.

## 3.3 Senior interaction rules

- Allow search, filters, history, and more precise progress details.

- Keep academic records separate from gamified records, even when both appear on Home.

- Communities, friends, challenges, and sharing must expose privacy, block, report, and notification controls.

- Use contextual companion appearances rather than constant interruption.

## 3.4 Teacher data-entry rules

- The teacher must be able to complete attendance and marks without horizontal scrolling on a normal phone.

- Use frozen student identity cells, vertically stacked fields, compact rows, and a focused next-student workflow instead of imitating a wide desktop spreadsheet.

- Bulk import uses downloadable templates prefilled with student names and stable identifiers. Uploads always pass through preview and validation before commit.

- Draft state is clearly distinct from submitted or published state.

## 3.5 Web administration rules

- Bulk actions show the affected count and require confirmation for destructive or privileged changes.

- Imports are two-step: upload and validate, then confirm and commit.

- Every table supports useful filters, empty states, loading states, export where required, and permission-aware actions.

- School branding changes never alter core accessibility or break contrast requirements.

# 4. Technical Architecture

## 4.1 Recommended architecture

Use feature-first MVVM with a clear data layer. Each feature owns its Views and ViewModels. Repositories expose domain-focused operations. Services wrap external systems such as Supabase, storage, notifications, media playback, voice, analytics, and game hosting. Privileged business operations run on the server.

| Why not pure MVVM folders? A global folders-by-layer structure becomes painful at Nano’s size. Feature-first organization keeps each module understandable and independently testable while retaining MVVM inside the feature. |
| --- |

| Layer | Responsibility | Must not do |
| --- | --- | --- |
| View | Render state, collect input, expose accessibility semantics, and forward user intent. | Contain SQL, calculate authoritative scores, award XP, or decide permissions. |
| ViewModel | Coordinate UI state, validation, commands, and repository calls. | Know database schemas, invoke unrelated modules directly, or store secrets. |
| Repository | Provide domain operations and map service responses into domain models. | Render UI or bypass server authority. |
| Service | Wrap Supabase clients, storage, video, notifications, device APIs, and third-party SDKs. | Contain product-specific screen logic. |
| Domain operation | Enforce use-case rules such as submitQuiz, publishAssessment, awardXp, approveJoinRequest. | Trust client-calculated final outcomes. |
| Database / Edge Function | Authorize privileged mutations, score, deduplicate, validate, audit, and integrate with external services. | Expose service-role credentials to Flutter. |

## 4.2 Logical system diagram

Flutter Mobile Apps                         Flutter Web Portals
Student Shell | Teacher Shell                 School Shell | Superadmin Shell
        \             /                              \            /
         Shared Domain Packages, Repositories, Services, Design Tokens
                              |
                     Supabase Client Gateway
                              |
      Auth + Postgres/RLS + Storage + Realtime + Edge Functions
                              |
       Trusted scoring | XP ledger | imports | notifications | audit
                              |
      External providers: video, push, voice, generated media, game hosts

## 4.3 Application packages

| Package | Purpose |
| --- | --- |
| apps/student_app | Student mobile application with Junior and Senior shells. |
| apps/teacher_app | Teacher mobile application. |
| apps/admin_web | School management and superadmin web application with permission-driven routes. |
| packages/nano_design | Design tokens, themes, typography, spacing, icons, responsive helpers, shared components. |
| packages/nano_domain | Domain models, value objects, permissions, result types, use-case interfaces. |
| packages/nano_data | Repositories, Supabase services, DTO mapping, cache adapters, sync queue. |
| packages/nano_auth | Session handling, role resolution, school context, onboarding guards. |
| packages/nano_media | Video, captions, audio focus, voice playback, asset caching, generated companion clips. |
| packages/nano_games | Game catalog, host bridge, score envelopes, verification client, web-game sandbox. |
| packages/nano_testing | Fixtures, fake repositories, golden helpers, test identities, RLS test utilities. |

## 4.4 Dependency direction

- Apps depend on shared packages. Shared packages never import an app.

- Feature Views depend on their ViewModels and design package, not directly on Supabase.

- ViewModels depend on repository interfaces from the domain package.

- Repository implementations depend on services and DTOs from the data package.

- Cross-feature communication uses typed domain events or a shared domain service, not direct ViewModel references.

- Experimental providers sit behind interfaces so they can be replaced without touching UI code.

## 4.5 State management

Keep the handbook provider-neutral at first. Select one state-management approach after the existing repository audit. The required properties are testable ViewModels, explicit loading and error states, dependency injection, predictable disposal, and no hidden global mutable state. The architecture must survive a later package change.

# 5. Repository and Code Organization

## 5.1 Proposed repository structure

nano/
  apps/
    student_app/
      lib/app/                # bootstrap, routes, guards, shell
      lib/features/           # onboarding, home, learning, quiz, flex, games...
      test/ integration_test/
    teacher_app/
    admin_web/
  packages/
    nano_design/
    nano_domain/
    nano_data/
    nano_auth/
    nano_media/
    nano_games/
    nano_testing/
  supabase/
    migrations/
    functions/
    seed/
    tests/                    # pgTAP and policy tests
  assets/
    shared/
    junior/
    senior/
    companion/
    licenses/
    provenance/
  docs/
    handbook/
    architecture-decisions/
    modules/
    api-contracts/
    data-dictionary/
  scripts/
    imports/
    code_audit/
    asset_audit/
    release/
  TASKS.md
  AGENTS.md
  README.md

## 5.2 Feature folder template

features/quiz/
  presentation/
    views/
    widgets/
    view_models/
    ui_models/
  domain/
    models/
    repository.dart
    use_cases/
  data/
    dto/
    repository_impl.dart
  routes/
  fixtures/
  test/
  README.md                 # purpose, scope, dependencies, states, events
  MODULE_STATUS.md          # mock/real backend, tests, known gaps

## 5.3 Module independence contract

- Every feature has one public entry point and a small exported API.

- Every feature can run against fake repositories with deterministic fixture data.

- Every feature documents its inbound dependencies, outbound events, owned tables, and feature flags.

- Deleting an experimental module must not break unrelated features.

- UI screenshots and golden tests belong beside the feature that owns them.

- No feature reaches into another feature’s internal folder.

# 6. Data, Security, Tenancy, and Server Authority

## 6.1 Identity model

Use one authentication identity per person and separate it from memberships and role assignments. A user may be an independent student, later join a school, or hold multiple authorized memberships without duplicating the core identity.

| Entity | Purpose |
| --- | --- |
| auth.users | Supabase authentication identity. Never used as the only authorization source. |
| profiles | Safe user profile, preferences, language, avatar, companion name, account status. |
| schools | Tenant record, immutable school code, status, branding, active academic year. |
| school_memberships | Connects a profile to a school and records role, status, dates, and school-scoped identity. |
| student_enrollments | Class, section, roll number, academic year, active dates, and history. |
| teacher_assignments | Teacher-to-class/section/subject scope with active dates. |
| platform_roles | Controlled superadmin and platform operations roles. |

## 6.2 Multi-school security rules

- RLS is enabled on every exposed table. No production table in the public API is left without policies.

- School-owned rows carry school_id or can derive it through an immutable relationship that policies can verify.

- A teacher read or write policy checks an active membership and an active assignment for the requested class, section, subject, and date.

- A student policy checks the authenticated profile and restricts private records to self.

- School suspension blocks new data access and requires session revalidation.

- Service-role credentials exist only in protected server environments. They never ship in Flutter builds or generated JavaScript.

- Privileged actions produce audit events with actor, role, school, target, previous value where appropriate, reason, timestamp, and request identifier.

## 6.3 Trusted operations

| Operation | Authoritative location | Reason |
| --- | --- | --- |
| Submit quiz | Database function or authenticated Edge Function | Freeze attempt version, validate expiry, score, deduplicate, update progress, and create XP event atomically. |
| Publish marks | Database transaction/function | Validate totals and status values, transition draft to published, and notify students once. |
| Submit game score | Edge Function plus database verification rules | Validate signed session, score boundaries, version, replay protection, and reward cap. |
| Award or reverse XP | Database function | Immutable ledger, source-event uniqueness, level recalculation, and audit. |
| Bulk import | Staging tables plus server validation | Preview errors, prevent partial corrupt imports, and produce an import report. |
| Community moderation | Server function | Preserve evidence, enforce role checks, remove content, and update sanctions consistently. |

## 6.4 Versioning and history

- Published Learning Stack content is versioned. Edits create a new draft version rather than silently changing a student’s completed record.

- Quiz attempts store a snapshot or immutable reference to the exact question version and option set used.

- Assessments keep draft, published, corrected, and closed state transitions with history.

- Student enrollment and teacher assignment records use active date ranges rather than destructive replacement.

- Archived users and schools retain academic history unless a lawful deletion workflow explicitly applies.

# 7. Reuse-First Engineering and Existing Code Audit

Nano should not rebuild standard capabilities merely because AI can generate code quickly. Reuse saves time only when the dependency is maintained, licensed, secure, adaptable, and cheaper to understand than to replace.

## 7.1 Mandatory audit before implementation

- Copy the existing demo1 repository into the active workspace. Do not reference a local path that Cursor cannot read.

- Inventory Flutter apps, packages, backend folders, assets, tests, generated files, and licenses.

- Run static analysis, tests, and a clean build for each supported platform.

- Map existing screens and services to Nano modules. Classify each item as reuse, adapt, quarantine, or discard.

- Search for embedded secrets, service-role keys, hardcoded URLs, personal data, and copied assets without provenance.

- Produce docs/code-audit/existing-code-report.md before merging any old code into the new structure.

## 7.2 Reuse decision scorecard

| Criterion | Question | Reject when |
| --- | --- | --- |
| License | Can Nano legally modify, distribute, and commercially use it? | License is missing, incompatible, or attribution cannot be met. |
| Maintenance | Is the project active and compatible with current Flutter/Dart? | Abandoned, unpatched, or tied to obsolete APIs. |
| Security | Does it handle auth, WebView, file upload, or networking safely? | Unknown data flows, unsafe JavaScript bridges, or broad permissions. |
| Fit | Can it meet Nano UX and domain rules without major rewrites? | Adapting costs more than a clean small implementation. |
| Isolation | Can it sit behind an interface or inside one module? | It forces app-wide coupling or owns global state. |
| Testing | Can it be covered with automated tests and deterministic fixtures? | Core behavior is opaque or not reproducible. |

## 7.3 Internet search order

- First: official Flutter and Dart packages and maintained platform plugins.

- Second: established open-source packages with clear licenses, recent maintenance, and strong issue history.

- Third: complete reference applications used as learning material, not copied blindly.

- Fourth: small code snippets after license and correctness review.

- Never: random downloadable binaries, opaque SDKs, copied assets, or code that requires exposing secrets in the client.

## 7.4 Provenance record

Every reused component receives a record under assets/licenses or docs/provenance containing source name, license, version or commit, files used, modifications, attribution requirement, reviewer, and replacement plan.

# 8. Design System and UI-First Workflow

## 8.1 Why UI first is useful

Building the visual shell first gives the product owner something concrete to review and creates stable contracts for data loading, empty states, and actions. But UI-first must not become screenshot-only development. Every screen receives fixtures, semantics, responsiveness rules, and a state contract before backend integration.

## 8.2 Reference-image replication workflow

- Store each approved reference image under docs/ui-references with a module ID, audience, device size, and approval status.

- Extract measurable tokens: spacing, radius, typography, card proportions, icon size, image placement, navigation height, and content density.

- Build the screen from reusable Nano components rather than one-off positioned widgets.

- Create golden tests at the exact reference viewport and at one smaller and one larger viewport.

- Record intentional deviations in the module README. Do not silently “improve” an approved reference.

- Only after visual approval, connect the real ViewModel and repository while preserving the same state model.

## 8.3 Design token groups

| Token group | Examples |
| --- | --- |
| Color | Brand primary, surfaces, text, success, warning, error, junior world palettes, senior accents, school branding slots. |
| Typography | Display, title, body, label, numeric data, Urdu fallback, line-height, scaling limits. |
| Spacing | 4-point base scale, page gutters, card padding, list gaps, safe-area spacing. |
| Shape | Junior large radius, senior medium radius, admin compact radius, pills, avatars, sheets. |
| Motion | Duration, easing, reduced-motion alternatives, companion cooldowns. |
| Elevation | Cards, dialogs, sticky controls, web sidebars. |
| Breakpoints | Small phone, large phone, tablet, narrow web, standard desktop, wide desktop. |

## 8.4 Component families

- NanoScaffold, NanoAppBar, responsive page container, bottom navigation, web side rail.

- JuniorActionCard, SeniorProgressCard, AdminMetricCard, TeacherTaskCard.

- SubjectWorldCard, TopicCard, VideoCard, QuizChoice, ResultSummary, XPChip.

- EmptyState, ErrorState, OfflineBanner, SyncStatus, SuspendedState, FeatureDisabledState.

- ValidatedTextField, secure password field, date selector, school selector, class/section selector.

- ResponsiveDataTable, import preview table, mobile student-entry row, filter bar, export action.

- CompanionSlot that can render static art, animation, short clip, or nothing without changing page layout.

## 8.5 Accessibility contract

- Text scaling and layout reflow are tested, not merely enabled.

- All controls have semantic labels and logical focus order.

- Captions exist for learning and companion media when speech is used.

- Color is never the only indicator of attendance status, correctness, or publishing state.

- Reduced motion replaces non-essential animation with fades or static state changes.

- English and Urdu layouts are tested for overflow and reading direction where required.

- Minimum touch targets and contrast remain valid after school branding is applied.

# 9. Module Catalog

Each module is independently testable, feature-flagged, and documented. Release labels describe intended sequencing, not permanent importance.

## FND-01  Workspace, Environments, and Configuration

Creates the repository foundation, local setup, environment separation, secrets policy, and repeatable developer commands.

| Field | Definition |
| --- | --- |
| Primary users | Developers and CI |
| Release target | R0 |
| Depends on | None |
| Owns | Workspace configuration, environment loader, build flavors, CI entry points |

### Scope

- Monorepo workspace and package dependency rules.

- Development, staging, and production configuration.

- Supabase local development setup and migration workflow.

- Feature-flag client and server contract.

- No secrets in source control; checked example environment files only.

### Main screens and states

- Developer-only diagnostics page in non-production builds.

- Environment badge in debug builds.

### Business rules

- Production builds fail if debug endpoints or test credentials are present.

- Every migration is forward-only in shared environments and has a tested rollback or compensating plan.

### Core data and interfaces

- EnvironmentConfig, FeatureFlag, BuildInfo, ServiceEndpoint.

### Acceptance gate

- One command analyzes and tests all packages.

- Fresh clone can run local apps with documented setup.

- CI blocks formatting, analyzer, unit-test, and migration failures.

## FND-02  Design System and Responsive Shells

Provides approved visual tokens, shared components, responsive behavior, and Junior/Senior/Admin theme families.

| Field | Definition |
| --- | --- |
| Primary users | All apps |
| Release target | R0 |
| Depends on | FND-01 |
| Owns | nano_design package, component catalog, themes, accessibility primitives |

### Scope

- Junior, Senior, Teacher, School Web, and Superadmin theme variants.

- Reusable loading, empty, error, offline, disabled, and suspended states.

- Reference-image golden test harness.

- English and Urdu typography slots.

### Main screens and states

- Component gallery available only in development.

- Responsive shell previews for phone, tablet, and web.

### Business rules

- School branding may fill approved brand slots but cannot override safety colors or required contrast.

- No module introduces hardcoded spacing or colors without a documented exception.

### Acceptance gate

- Core components pass golden tests.

- Text scaling and small-device smoke tests pass.

- The same domain card can render appropriate Junior and Senior variants.

## FND-03  Authentication, Sessions, and Role Resolution

Handles sign-in, first-login password changes, recovery, session restoration, account status, and route guards.

| Field | Definition |
| --- | --- |
| Primary users | Students, teachers, school staff, superadmins |
| Release target | R1 |
| Depends on | FND-01, SEC-01 |
| Owns | Auth UI, session state, profile bootstrap, active membership selection |

### Scope

- School code plus login ID flows for school users.

- Independent student signup and recovery.

- Temporary password change.

- Suspended account and suspended school explanations.

- Shared-device logout and session revocation.

### Main screens and states

- Role-specific sign-in.

- First-login password change.

- Recovery request.

- Account or school suspended state.

- Membership selection when a user has more than one valid context.

### Business rules

- A client route guard is convenience only; RLS remains authoritative.

- Session restoration re-checks school and membership status before showing private data.

### Core data and interfaces

- profiles, schools, school_memberships, platform_roles, device_sessions, login_events.

### Failure, offline, and recovery behavior

- Previously cached private content is hidden after logout or membership suspension.

- Offline sign-in is not allowed.

### Acceptance gate

- Users land only in permitted shells.

- Revoked sessions lose access.

- RLS tests cover each role and suspended state.

## FND-04  Navigation, Deep Links, and App Shells

Defines role-aware routes, eligibility-aware navigation, deep-link handling, and shell state.

| Field | Definition |
| --- | --- |
| Primary users | All app users |
| Release target | R0/R1 |
| Depends on | FND-02, FND-03 |
| Owns | Route definitions, guards, shell navigation, destination visibility |

### Scope

- Junior and Senior student shells.

- Teacher shell.

- School and superadmin web shells.

- Deep links from notifications.

- Independent-student navigation without Flex placeholders.

### Business rules

- Hidden destinations are not reachable through direct URLs without permission.

- A notification deep link falls back to a safe parent screen when the target is unavailable.

### Acceptance gate

- All routes have permission and feature-flag tests.

- Back navigation and browser refresh preserve valid state.

## SEC-01  Tenancy, RLS, Audit, and Permission Engine

Implements school isolation, assignment scope, least privilege, privileged-action logging, and reusable permission checks.

| Field | Definition |
| --- | --- |
| Primary users | All |
| Release target | R1 |
| Depends on | FND-01 |
| Owns | RLS policies, role functions, audit_events, permission contracts |

### Scope

- School and platform roles.

- Teacher assignment checks.

- Student self-only records.

- School suspension.

- Audit for privileged and corrective actions.

- Policy test suite with adversarial identities.

### Business rules

- No exposed table without RLS.

- No client can award XP, publish marks, or bypass school scope.

- Audit records are append-only to ordinary users.

### Core data and interfaces

- school_memberships, teacher_assignments, platform_roles, audit_events, security_incidents.

### Acceptance gate

- Cross-school read/write tests fail as expected.

- Least-privilege matrices are reviewed before each release.

- Service-role usage is isolated to protected functions.

## FND-05  Local Cache and Sync Queue

Supports reliable reads and limited draft work during weak connectivity without creating conflicting authoritative records.

| Field | Definition |
| --- | --- |
| Primary users | Students and teachers |
| Release target | R1 |
| Depends on | FND-03, SEC-01 |
| Owns | Cache adapters, sync envelopes, conflict state, last-updated metadata |

### Scope

- Cached read-only dashboards and content metadata.

- Quiz resume state.

- Teacher attendance and marks drafts for short interruptions.

- Pending game verification.

- Queued community messages only in later safety-gated release.

### Business rules

- Offline does not mean trusted. Final score, publish, XP, and membership decisions wait for server confirmation.

- Every queued mutation has an idempotency key and visible state.

### Failure, offline, and recovery behavior

- Show last-updated timestamps.

- Offer retry, discard, or resolve actions for failed queues.

- Never silently overwrite a newer server version.

### Acceptance gate

- Airplane-mode tests cover supported flows.

- Duplicate retries do not create duplicate attendance, attempts, marks, or XP.

## STU-01  Student Onboarding and Preferences

Introduces Nano, resolves Junior or Senior experience, configures the companion name, language, sound, and accessibility.

| Field | Definition |
| --- | --- |
| Primary users | School-linked and independent students |
| Release target | R1 |
| Depends on | FND-02, FND-03 |
| Owns | Onboarding completion, student preference UI |

### Scope

- Companion introduction.

- Student-selected companion name with Nori as default.

- Language selection.

- Sound, captions, motion, and accessibility preferences.

- School identity presentation for linked students.

- Natural independent-student introduction without blocked school features.

### Business rules

- Experience is derived from grade policy but may have an authorized override.

- Preferences sync to profile but have safe local defaults.

### Acceptance gate

- Onboarding can resume after interruption.

- Junior copy is audio-supportive and minimal.

- Independent onboarding never promises school-only features.

## STU-02  Student Home

Answers what happened, what to do next, and how the student is progressing.

| Field | Definition |
| --- | --- |
| Primary users | Students |
| Release target | R1 |
| Depends on | STU-01, FND-04, relevant data modules |
| Owns | Home composition and aggregation ViewModel |

### Scope

- Greeting, avatar, companion slot, Continue Learning, latest relevant update, progress, goals, notifications, and shortcuts.

- Junior large-action composition.

- Senior level, XP, streak, Flex summary when eligible, and Today’s Plan.

- Maintenance, payment/access warning, and offline timestamp states.

### Business rules

- Home aggregates read models; it does not duplicate source-of-truth calculations.

- Independent Home fills school-only space with useful learning or game content rather than locks.

### Acceptance gate

- Home renders with partial data when one source fails.

- Junior has one obvious next action.

- Senior cards deep-link correctly.

## PRF-01  Profiles, Progress, Settings, and Device Controls

Provides role-appropriate identity, progress, privacy, accessibility, security, and media preferences without mixing private academic data into social profiles.

| Field | Definition |
| --- | --- |
| Primary users | Students and teachers |
| Release target | R1 basic; R2 expanded |
| Depends on | FND-03, FND-02, NOT-01 |
| Owns | Profile screens, preference editing, featured achievements, device-session UI |

### Scope

- Student identity, avatar, companion name, class/school context, account type, and language.

- Learning progress, completed topics, quiz and game history, personal bests, league record, strengths, improvement areas, and recommended next activity.

- Friends, communities, blocks, reports, and privacy controls when enabled.

- Teacher identity, assignments, workload summary, preferences, password, sessions, logout, and support.

- Light/dark appearance, font size, captions, companion, music, sound effects, haptics, notifications, quiet hours, privacy, and accessibility.

### Business rules

- Public or friend-visible profiles use a safe projection and never expose email, phone, guardian data, attendance, marks, results, payment, or device information.

- Junior sensitive settings require a guardian gate or school policy.

- Device session revocation is server-backed and audited when privileged.

### Core data and interfaces

- profiles, profile_preferences, featured_achievements, device_sessions, privacy_settings.

### Acceptance gate

- Student and teacher profiles render from role-safe read models.

- Privacy changes affect discovery and social visibility immediately.

- Logout clears private local caches.

## LRN-01  Learning Stack Catalog

Delivers superadmin-curated subjects, topics, prerequisites, progress, and next recommendations.

| Field | Definition |
| --- | --- |
| Primary users | Students and superadmin content team |
| Release target | R1 |
| Depends on | SEC-01, FND-02 |
| Owns | Learning catalog reads, subject/topic browsing, publication model |

### Scope

- Subject eligibility, search for Senior users, topic order, locked prerequisites, estimated time, objectives, supporting resources, progress, and resume state.

- Junior subject worlds and illustration-led topic selection.

- Junior and Senior preview before publication.

### Business rules

- School-created subjects are not part of Learning Stack unless separately mapped for reporting.

- Published versions are immutable to existing completion records.

### Core data and interfaces

- learning_subjects, subject_versions, topics, topic_versions, prerequisites, eligibility_rules, learning_progress.

### Acceptance gate

- Unpublished content is invisible.

- Prerequisites and eligibility are enforced on server reads.

- Junior and Senior previews use identical underlying version IDs.

## LRN-02  Video Learning and Progress

Plays approved learning videos, resumes position, verifies completion, and triggers the ordered quiz.

| Field | Definition |
| --- | --- |
| Primary users | Students |
| Release target | R1 |
| Depends on | LRN-01, MED-01 |
| Owns | Video session, progress heartbeat, transcript/caption UI |

### Scope

- In-app approved provider playback.

- Resume position.

- Completion thresholds and progress tracking.

- Transcript or captions where available.

- Long-video refresh moments.

- Companion slot in unused player space.

### Business rules

- Do not interrupt videos every ten minutes blindly. For videos over thirty minutes, schedule optional refresh checkpoints at pedagogically safe boundaries; never cut a sentence or assessment segment.

- Completion is based on server-defined rules, not a single client boolean.

- Seeking policy is configurable by content.

### Core data and interfaces

- video_assets, video_sessions, playback_progress, completion_events.

### Failure, offline, and recovery behavior

- Previously downloaded metadata may display; playback availability depends on provider and policy.

- Progress heartbeats retry with idempotency.

### Acceptance gate

- Resume works across app restarts.

- Completion cannot be duplicated.

- Quiz becomes available only for the correct published video version.

## QZ-01  Quiz Authoring and Versioning

Lets superadmins attach an ordered quiz to a specific video and safely publish its exact version.

| Field | Definition |
| --- | --- |
| Primary users | Superadmin content team |
| Release target | R1 |
| Depends on | LRN-01, SEC-01 |
| Owns | Question bank, quiz drafts, publication, preview |

### Scope

- Manual question creation.

- Bulk import.

- Ordered question sequence.

- Option order policy.

- Correct answers, explanations, difficulty, language, media, pass requirement, timer, retakes, and expiry.

- Junior and Senior preview.

- Duplicate-question warnings and provenance.

### Business rules

- Each published quiz version is immutable.

- A video points to one active quiz version per eligible language/experience policy.

- Question sequence is preserved unless randomization is explicitly enabled.

### Core data and interfaces

- question_bank, question_versions, quiz_versions, quiz_items, quiz_policies.

### Acceptance gate

- Preview matches student rendering.

- Publishing records actor and version.

- Retiring a quiz does not break historical attempts.

## QZ-02  Student Quiz Attempt and Scoring

Runs the companion-led quiz, saves answers, resumes safely, scores on the server, and updates progress.

| Field | Definition |
| --- | --- |
| Primary users | Students |
| Release target | R1 |
| Depends on | QZ-01, CMP-01, GAM-01 |
| Owns | Attempt UI, autosave, submit command, result summary |

### Scope

- One question per screen for Junior.

- Senior navigation and review where policy allows.

- Audio instructions, progress, optional timer, answer autosave, resume, submit confirmation, explanations, result, history, and recommendations.

- Companion reactions for correct, wrong, retry, hint, and completion.

### Business rules

- The client never determines the final score.

- Attempt stores the published quiz and question snapshot.

- Submit is idempotent and duplicate-safe.

- Repeated wrong answers trigger gentle guidance, not shame.

### Core data and interfaces

- quiz_attempts, attempt_answers, attempt_events, score_results, suspicious_attempt_flags.

### Failure, offline, and recovery behavior

- Answers may be locally queued within the active attempt policy.

- Final submit requires server confirmation unless a future signed offline assessment mode is deliberately designed.

### Acceptance gate

- Closing and reopening preserves the attempt.

- Duplicate submit returns the same result.

- XP and topic completion are atomic with scoring.

## FLX-01  Student Flex

Shows school-linked academic attendance, published marks, results, Classroom content, and teacher remarks.

| Field | Definition |
| --- | --- |
| Primary users | School-linked students |
| Release target | R1 |
| Depends on | SEC-01, ATT-01, MRK-01, CLS-01 |
| Owns | Student academic read views |

### Scope

- Flex overview.

- Attendance calendar and summaries.

- Published assessments, report cards, and history.

- Classroom announcements and resources.

- Junior labels My Days and My Work.

- Filters by subject, term, and month.

### Business rules

- Independent students never receive Flex navigation or data.

- Draft marks and private teacher notes are excluded at query level, not merely hidden in UI.

### Acceptance gate

- Students can only see their own records.

- Published corrections update with history.

- Junior cards support read-aloud and one action.

## TCH-01  Teacher Dashboard and My Classes

Shows assigned scope, pending tasks, class rosters, and permitted student summaries.

| Field | Definition |
| --- | --- |
| Primary users | Teachers |
| Release target | R1 |
| Depends on | FND-03, SEC-01, SCH-03 |
| Owns | Teacher dashboard read models and class navigation |

### Scope

- Assigned classes, sections, and subjects.

- Pending attendance, draft assessments, unpublished marks, recent Classroom items, notifications, and quick actions.

- Student basic profiles and permitted academic summaries.

- Teacher badge in communities when later enabled.

### Business rules

- Expired or replaced assignments immediately remove access.

- The dashboard may aggregate counts but cannot widen the teacher’s underlying permissions.

### Acceptance gate

- An unassigned class cannot be opened by route manipulation.

- Pending counts match source records.

## ATT-01  Attendance Management

Supports reliable teacher attendance entry, bulk import, submission, correction, and student views.

| Field | Definition |
| --- | --- |
| Primary users | Teachers, students, school management |
| Release target | R1 |
| Depends on | TCH-01, FND-05, SCH-02 |
| Owns | Attendance sessions, entries, corrections, import templates |

### Scope

- Select assigned class, section, subject/period, and date.

- Load expected roster.

- Mark all present and change exceptions.

- Present, absent, late, leave, and excused states.

- Mobile single-view entry.

- Download prefilled Excel template, validate upload, preview, and commit.

- Correction with reason and history.

### Business rules

- One active attendance session per configured scope and date.

- Retries use idempotency keys.

- Corrections never erase previous values.

- Bulk upload references stable student IDs, not names alone.

### Core data and interfaces

- attendance_sessions, attendance_entries, attendance_corrections, import_jobs, import_rows.

### Failure, offline, and recovery behavior

- Draft entry can persist locally for short interruptions.

- Submission waits for server and shows conflicts if another authorized user already submitted.

### Acceptance gate

- No horizontal scrolling is required on target phone.

- Bulk and in-app entry produce the same canonical records.

- Duplicate submission is prevented.

## MRK-01  Assessments, Marks, and Results

Allows teachers to create assessments, enter or import marks, publish, correct, and support school result policies.

| Field | Definition |
| --- | --- |
| Primary users | Teachers, students, school management |
| Release target | R1 |
| Depends on | TCH-01, SCH-02, SEC-01 |
| Owns | Assessments, marks entries, publication states, correction history |

### Scope

- Custom categories and names.

- Date, total marks, optional weight, description.

- Mobile grid entry, copy/paste where supported, and Excel template import.

- Absent, exempt, not submitted, and remarks.

- Draft, validation, publish, correction, export, and class summary.

- School-configured grades, passing rules, report cards, and period closure.

### Business rules

- Draft records are private.

- Obtained marks cannot exceed total unless a documented bonus policy exists.

- Publishing is a server transaction and generates notifications once.

- Corrections require reason and preserve history.

### Core data and interfaces

- assessments, assessment_versions, marks_entries, marks_corrections, grading_policies, result_periods, report_cards.

### Acceptance gate

- Students never see drafts.

- Import validation identifies duplicate students and invalid values before commit.

- Closed periods require privileged correction workflow.

## CLS-01  Classroom Announcements and Materials

Lets teachers publish subject-scoped announcements and learning resources to assigned students.

| Field | Definition |
| --- | --- |
| Primary users | Teachers and school-linked students |
| Release target | R1 |
| Depends on | TCH-01, MED-01, NOT-01 |
| Owns | Classroom items, attachments, acknowledgements, archives |

### Scope

- Teacher selects an assigned subject and target class/section.

- Announcements, scheduled publication, expiry, acknowledgements, PDFs, images, guides, approved links, videos, revision material, and assignment instructions.

- Open and acknowledgement counts.

- Student search, filters, folders, and archive.

### Business rules

- Teacher can publish only within active assignment scope.

- File type, size, malware scan, and link allowlist policies apply.

- Expired content remains in history according to school policy.

### Acceptance gate

- A student receives only applicable items.

- Junior item has one clear action and read-aloud support.

- Acknowledgements are auditable.

## SCH-01  School Setup and Branding

Creates and configures a school tenant and its first administrator.

| Field | Definition |
| --- | --- |
| Primary users | Superadmin and school management |
| Release target | R1 |
| Depends on | SEC-01 |
| Owns | School identity, status, branding, academic-year settings |

### Scope

- Create school and immutable code.

- First principal/admin account.

- Name, logo, address, contact, banner, and approved theme slots.

- Activate, suspend, reactivate, and setup progress.

- Current academic year and school feature flags.

### Business rules

- School code is immutable after creation.

- Suspending an administrator does not automatically suspend the school.

- Brand colors are accessibility-validated.

### Acceptance gate

- New school can complete setup without platform database access.

- Suspension is enforced in active sessions.

## SCH-02  Academic Structure

Defines grades, classes, sections, school subjects, terms, and mappings used by academic modules.

| Field | Definition |
| --- | --- |
| Primary users | School management |
| Release target | R1 |
| Depends on | SCH-01 |
| Owns | Grades, classes, sections, subjects, terms, policies |

### Scope

- Create and archive grade levels, classes, and sections.

- Create school subject names and map to platform catalog when useful.

- Assign subjects to classes and sections.

- Configure attendance mode, grading, passing, weights, and report-card format.

- Detect missing and duplicate mappings.

### Business rules

- Used structures are archived rather than deleted.

- Historical records retain the original structure references.

### Acceptance gate

- Teacher assignment and imports cannot reference invalid or archived structures outside allowed dates.

## SCH-03  School Users, Imports, and Enrollment

Manages teachers, students, credentials, enrollment history, promotion, transfer, and account status.

| Field | Definition |
| --- | --- |
| Primary users | School management |
| Release target | R1 |
| Depends on | SCH-01, SCH-02, FND-03 |
| Owns | School user management, import staging, enrollment lifecycle |

### Scope

- Create individual teacher/student.

- Excel templates, upload preview, duplicate detection, validation, commit report.

- Manual IDs and temporary credentials.

- Activate, suspend, reactivate, archive, reset password, and force password change.

- Bulk promotion, section transfer, bulk status updates.

- Link an independent account to the school without losing progress.

- Guardian details and future linking.

### Business rules

- History is preserved when a student leaves or graduates.

- Duplicate identity resolution is explicit; the importer never silently creates a second profile.

- Guardian data is private and excluded from social profiles.

### Acceptance gate

- Failed rows do not partially corrupt committed rows.

- Import report can be downloaded.

- Independent account linking preserves learning and game history.

## SCH-04  Teacher Assignment and Workload

Controls teacher access by class, section, subject, and active dates and exposes workload visibility.

| Field | Definition |
| --- | --- |
| Primary users | School management and teachers |
| Release target | R1 |
| Depends on | SCH-02, SCH-03, SEC-01 |
| Owns | teacher_assignments and workload views |

### Scope

- Assign, co-assign where allowed, replace, date-limit, and review history.

- Conflict and unassigned-subject detection.

- Workload counts for students, attendance, marks, materials, feedback, and community responsibilities.

### Business rules

- Permissions derive from active assignment records.

- Replacing a teacher does not alter historical authorship.

### Acceptance gate

- Access updates when assignment dates begin or end.

- Conflicts and uncovered subjects are visible before publication of timetable-related responsibilities.

## ADM-01  Global School and Account Operations

Gives platform staff controlled tools for schools, users, sessions, suspicious access, and audit.

| Field | Definition |
| --- | --- |
| Primary users | Platform superadmins |
| Release target | R1 |
| Depends on | SEC-01, SCH-01 |
| Owns | Global operational views and privileged account actions |

### Scope

- Search across schools with safe summaries.

- School status and setup progress.

- Replace school administrator.

- Suspend/reactivate user.

- Password reset, revoke session, investigate access denial, login timeline, audit changes.

### Business rules

- High-risk actions require stronger authentication and explicit reason.

- Superadmin access is logged and should be periodically reviewed.

### Acceptance gate

- Every privileged action creates an audit event.

- Search results minimize unnecessary personal data.

## ADM-02  Learning Content Administration

Provides end-to-end creation, preview, publication, retirement, and audit for Learning Stack content.

| Field | Definition |
| --- | --- |
| Primary users | Platform content team |
| Release target | R1 |
| Depends on | LRN-01, QZ-01, MED-01 |
| Owns | Content authoring web workflows |

### Scope

- Subjects, covers, eligibility, topics, ordering, prerequisites, time, video, article, PDF, images, supporting resources, language, source, junior/senior preview, publication history.

- Question bank and specific video quiz linking.

### Business rules

- Publishing requires required metadata, valid media, and a preview check.

- Retirement prevents new starts but preserves history.

### Acceptance gate

- A content editor can publish a full subject-to-video-to-quiz path without developer assistance.

## GAM-01  XP, Levels, Achievements, Missions, and Streaks

Creates a trusted, auditable motivation system separate from school academics.

| Field | Definition |
| --- | --- |
| Primary users | Students and superadmins |
| Release target | R1 basic; R2 full |
| Depends on | SEC-01 |
| Owns | XP ledger, level rules, achievements, missions, streaks |

### Scope

- Small video completion XP.

- Quiz score-based XP.

- Verified game XP.

- Level thresholds, achievements, stickers, daily/weekly missions, streaks, titles, featured achievements, manual adjustments with reason, reversals, caps.

### Business rules

- Attendance and school marks do not award XP.

- Each award references a unique source event.

- Caps and anti-abuse rules run server-side.

- Broken streak messaging is gentle.

### Core data and interfaces

- xp_ledger, level_rules, achievement_definitions, achievement_awards, missions, mission_progress, streaks.

### Acceptance gate

- Replay and duplicate events cannot award twice.

- Ledger totals reconcile to profile level.

- Manual adjustments require reason and audit.

## LGE-01  Leagues, Leaderboards, and Competitive Challenges

Runs time-bounded, privacy-safe competition based on verified game performance while protecting younger students from harmful pressure.

| Field | Definition |
| --- | --- |
| Primary users | Students, school management, superadmin |
| Release target | R2; challenges depend on SOC-01 |
| Depends on | GAM-01, GME-01, SEC-01 |
| Owns | League cycles, leaderboard snapshots, promotion/relegation, ranking history |

### Scope

- Weekly league cycles and divisions.

- Promotion and relegation zones, countdown, previous result, participation status, and history.

- Class, section, school, friends, subject-game, weekly, and monthly leaderboards where policy allows.

- Personal position card and privacy-safe display name.

- Challenge invitations, fixed game/quiz version, expiry, result, tie, and rematch through SOC-01.

### Business rules

- Ranking uses verified game performance, never school marks or attendance.

- Junior competition favors class/team progress, participation, and personal improvement; aggressive rank-loss messaging is prohibited.

- Leaderboard snapshots are computed server-side and cannot be edited by clients.

- Tie-break policy is versioned and visible to administrators.

### Core data and interfaces

- league_cycles, league_divisions, league_participants, leaderboard_snapshots, rank_history, challenge_rules.

### Acceptance gate

- Week rollover is deterministic and testable.

- Promotion/relegation cannot be changed by late duplicate scores.

- Privacy-safe names are used in every ranking view.

## GME-01  Game Catalog and Secure Game Host

Integrates approved web or Flutter games while keeping identity, score verification, versioning, and XP under Nano control.

| Field | Definition |
| --- | --- |
| Primary users | Students and superadmins |
| Release target | R2 |
| Depends on | GAM-01, MED-01, SEC-01 |
| Owns | Game catalog, session bridge, score submission, kill switch |

### Scope

- Categories, age/class eligibility, topic tags, detail, version, download/asset state, start, pause/resume, result, history, personal best, storage management, remote kill switch.

- Music, effects, voice, haptics, Classroom Mode, and reduced motion.

- Junior one-tap worlds and Senior catalog/filter experience.

### Business rules

- External game code never receives Supabase service credentials.

- Nano issues a short-lived signed game session and accepts only the documented bridge messages.

- Score boundaries, duration, version, replay token, and impossible patterns are validated before XP.

### Core data and interfaces

- games, game_versions, game_assets, game_sessions, game_score_submissions, game_results, rejected_scores.

### Failure, offline, and recovery behavior

- Results may remain pending until verification. The UI never shows unverified XP as final.

### Acceptance gate

- Kill switch blocks a compromised version immediately.

- A fake JavaScript score message cannot create XP.

- Licenses and provenance exist for every shipped game.

## SOC-01  Friends, Challenges, and Sharing

Supports controlled student relationships, fair challenges, and system-generated share cards.

| Field | Definition |
| --- | --- |
| Primary users | Senior students; limited Junior policy later |
| Release target | R3 safety-gated |
| Depends on | SEC-01, GAM-01, SAFE-01 |
| Owns | Friend graph, blocks, challenge lifecycle, share-card generation |

### Scope

- Username and friend code, suggestions by policy, requests, accept/decline/cancel/remove, block, report, limited profile, friends ranking.

- Challenge invite, expiry, fixed version, result, tie, and rematch.

- Generate a shareable result image for Communities, WhatsApp, or other share targets.

### Business rules

- Contact details, guardian data, attendance, marks, results, and payment remain private.

- Blocked users cannot challenge or discover each other.

- Share cards use privacy-safe names and never expose school records.

- Junior access, if enabled later, is school-limited and controlled, even if feature parity is desired.

### Acceptance gate

- Block takes effect across discovery, requests, challenges, and communities.

- Challenge competitors receive equivalent rules and version.

- Generated share card passes privacy review.

## COM-01  Senior Communities

Creates school-controlled or approved public communities with roles, join workflows, messages, media, and moderation.

| Field | Definition |
| --- | --- |
| Primary users | Senior students and teachers |
| Release target | R3 safety-gated |
| Depends on | SAFE-01, NOT-01, MED-01 |
| Owns | Communities, membership, content, moderation hooks |

### Scope

- My Communities, Discover, search, details, rules, join request, invitation, leave.

- Student-created communities where policy allows.

- Owner, admin, moderator, member, pending, removed, and banned states.

- Text, replies, mentions, voice messages, photos, videos, files, pins, announcements, reactions, search, mute, archive, and admin-only posting.

### Business rules

- Communities are hidden from Junior students.

- Private and school-controlled is the default. Public discoverability requires explicit policy and moderation readiness.

- Media and open conversation stay disabled until reporting, evidence preservation, rate limits, and moderator tools pass.

### Failure, offline, and recovery behavior

- Queued messages show pending/failed state and are subject to revalidation when sent.

### Acceptance gate

- A banned member cannot rejoin through stale links.

- Reports preserve necessary evidence.

- Rate limits and restricted-link rules are enforced server-side.

## SAFE-01  Community Safety and Moderation

Provides the controls required before social messaging or public discovery can launch.

| Field | Definition |
| --- | --- |
| Primary users | School moderators and platform safety team |
| Release target | R3 prerequisite |
| Depends on | SEC-01 |
| Owns | Reports, moderation cases, sanctions, restricted content policies |

### Scope

- Report categories, queue, evidence snapshots, warn, remove, suspend user, suspend community, ban where authorized, appeal notes, moderator audit, restricted terms/links, media rules, rate limits.

### Business rules

- Moderators see only the data necessary for the case.

- Evidence access is audited.

- Automated detection may prioritize review but does not silently issue severe sanctions without policy.

### Acceptance gate

- End-to-end report to resolution flow works.

- Blocked and sanctioned states are enforced in all social modules.

## CMP-01  Nori Companion and Learning Guide

Provides intentional companion guidance, reactions, captions, and a consistent voice without making generated media a hard dependency.

| Field | Definition |
| --- | --- |
| Primary users | Students |
| Release target | R1 core; later enrichment |
| Depends on | FND-02, MED-01 |
| Owns | Companion state machine, asset selection, cooldowns, voice scripts |

### Scope

- First opening, home, learning entry, video start/completion, quiz states, game result, achievements, level-up, missions, return from inactivity, and selected empty states.

- Core reactions: greeting, idle, point, thinking, gentle retry, small celebration.

- Aoede Learning Guide voice, captions, sound controls, Classroom Mode, reduced motion.

### Business rules

- Nori never calculates marks, score, XP, rank, or eligibility.

- Static approved master art is the default. Generated clips are optional enhancements inside a consistent branded frame.

- Junior sees larger and more frequent guidance; Senior sees smaller contextual guidance.

- Cooldowns prevent repeated interruption.

### Acceptance gate

- The app remains fully usable when every remote companion API is unavailable.

- Reaction selection is deterministic for tests.

- Captions and mute states work.

## MED-01  Media, Files, Audio, and Asset Delivery

Centralizes approved video providers, storage uploads, captions, audio focus, asset caching, and file safety.

| Field | Definition |
| --- | --- |
| Primary users | All relevant modules |
| Release target | R1 |
| Depends on | SEC-01 |
| Owns | Media service interfaces, upload policy, storage paths, playback coordination |

### Scope

- Video provider adapter.

- PDF/image/file upload.

- Caption tracks.

- Audio focus between video, quiz music, game music, and voice.

- Signed URLs and cache expiry.

- File type, size, and malware-scan hooks.

### Business rules

- Storage paths encode tenant scope where appropriate, and policies enforce ownership.

- External URLs use allowlists and safe opening rules.

- Only one foreground audio source plays unless deliberately mixed.

### Acceptance gate

- Unauthorized signed URL requests fail.

- Audio settings apply consistently.

- Large and invalid uploads fail with clear validation.

## NOT-01  Notifications and Inbox

Delivers in-app and push notifications with privacy, deep links, quiet hours, categories, and deduplication.

| Field | Definition |
| --- | --- |
| Primary users | Students, teachers, school staff |
| Release target | R1 basic; R2 full |
| Depends on | FND-03, FND-04 |
| Owns | Notification templates, events, inbox, device tokens, preferences |

### Scope

- Announcements, materials, marks publication, attendance concern, learning, quiz reminder, achievement, level, league, friend, community, game, payment/access, and account events.

- Unread count, filters, mark read, deep links, quiet hours, category mute, digest, cooldown, retries, token cleanup.

### Business rules

- Sensitive marks do not appear on lock screens.

- One source event creates at most one logical notification per recipient and channel policy.

- Mandatory account/security notices cannot be fully muted.

### Acceptance gate

- Deep links respect current permission.

- Duplicate event retries do not duplicate inbox items.

- Invalid tokens are cleaned safely.

## ANL-01  Analytics, Health, and Reporting

Measures product operation without turning child data into unnecessary surveillance.

| Field | Definition |
| --- | --- |
| Primary users | School management and platform operations |
| Release target | R1 operational; R2 expanded |
| Depends on | SEC-01 |
| Owns | Event taxonomy, aggregate views, school health score, operational reports |

### Scope

- Active schools/users, setup completion, attendance completion, assessment publication, learning and quiz participation, games, communities, reports/blocks, notification delivery, storage, database growth, cost, errors, crash-free sessions, support rate.

- School attendance, assessment, result, and teacher-activity reports.

### Business rules

- Collect only events tied to defined product or operational questions.

- School reports remain school-scoped.

- Child-facing behavior analytics use privacy-safe identifiers and retention policies.

### Acceptance gate

- Dashboard numbers can be traced to documented queries.

- Analytics failure never blocks core learning or attendance.

## BIL-01  Independent Access, Trials, and Billing

Manages free, trial, paid, expiring, and restricted access states for independent students without contaminating school-linked academic permissions.

| Field | Definition |
| --- | --- |
| Primary users | Independent students, guardians where applicable, platform operations |
| Release target | R4 future |
| Depends on | FND-03, NOT-01, SEC-01 |
| Owns | Plans, entitlements, access periods, payment status, billing notifications |

### Scope

- Free, trial, and paid access states.

- Plan eligibility and content/game entitlements.

- Payment success, failure, renewal, expiry, and grace period notifications.

- Later invitation to link the same account to a school while preserving independent progress.

### Business rules

- Payment status never grants school data access.

- Client receipts or payment callbacks are verified server-side.

- Expired users see a useful reduced-access experience rather than broken navigation.

- Children are not pushed with manipulative purchase pressure.

### Core data and interfaces

- plans, subscriptions, entitlements, payment_events, billing_accounts, access_periods.

### Acceptance gate

- Forged client payment state cannot unlock access.

- School linking preserves progress and cleanly separates school and paid entitlements.

## PAR-01  Guardian Guidance Module

Provides a future adult interface for linked children and weekly platform guidance.

| Field | Definition |
| --- | --- |
| Primary users | Parents or guardians |
| Release target | R4 future |
| Depends on | SCH-03, SEC-01, NOT-01 |
| Owns | Guardian links, weekly guidance cards, selected child summaries |

### Scope

- Superadmin uploads weekly report and activity guidance PDF.

- Guardian sees only linked children.

- Selected published information and structured teacher feedback may be added by policy.

### Business rules

- Draft marks and private teacher notes are never exposed.

- Guardian linking requires verified authorization.

### Acceptance gate

- A guardian cannot discover or access an unlinked child.

## FBK-01  Teacher-Guardian Structured Feedback

Supports academic and attendance communication without unrestricted personal chat.

| Field | Definition |
| --- | --- |
| Primary users | Teachers, guardians, school management |
| Release target | R4 or late pilot by school need |
| Depends on | PAR-01, TCH-01, NOT-01 |
| Owns | Feedback threads, categories, escalation, resolution |

### Scope

- Academic, attendance, behavior, and performance concerns.

- Suggested improvement action.

- Guardian reply, history, resolve, escalate, archive.

### Business rules

- Teacher can initiate only for assigned students.

- Messages are structured, school-visible according to policy, and auditable.

### Acceptance gate

- Thread scope and escalation permissions are tested.

# 10. Companion, Voice, and Generated Media Strategy

The companion is important, but a free or limited generation API cannot be allowed to control product reliability, visual identity, or cost. Nano should use a layered companion system: stable local assets for routine interactions, reusable short reactions for common events, and rare generated clips for special moments.

## 10.1 Controlled variation, not random inconsistency

- Keep one approved core identity: Nori, or the student’s chosen companion name, with recognizable face, emblem, color family, and voice.

- Treat visual variants as intentional “modes” or “story cards” inside a consistent portal frame. Examples: Explorer Nori, Quiz Coach Nori, Builder Nori, Celebration Nori.

- Use the same Aoede narration style, caption design, sound cue family, and entrance/exit treatment across variants.

- Never place two visibly different variants in the same short interaction unless the narrative explains it.

- Routine UI uses static or locally animated master assets. Generated video is reserved for onboarding, major level milestones, new-world introductions, or occasional seasonal moments.

## 10.2 Companion asset ladder

| Tier | Asset type | Use | Cost policy |
| --- | --- | --- | --- |
| Tier 0 | Static transparent PNG/WebP | Default neutral, point, think, retry, celebrate. | Bundled and unlimited. |
| Tier 1 | Small local animation | Blink, wave, bounce, subtle idle. | Bundled and reusable. |
| Tier 2 | Short pre-generated clip | Quiz intro, level-up, long-video refresh. | Generate once, cache, reuse by language where possible. |
| Tier 3 | Dynamic generated clip | Rare personalized or seasonal event. | Feature-flagged, quota-aware, cached, and never required. |

## 10.3 Reaction state machine

| Event | Junior behavior | Senior behavior | Fallback |
| --- | --- | --- | --- |
| Correct answer | Short positive animation and sound, then return to neutral. | Small corner reaction or inline badge. | Static success pose. |
| Wrong answer | Gentle retry, optional spoken hint, no red flash overload. | Brief contextual hint if policy allows. | Static thinking pose. |
| Repeated mistake | Pause, simplify instruction, offer hint or retry later. | Offer explanation or recommended review. | Text and accessible icon. |
| Quiz complete | Celebration proportional to effort and result. | Result summary with optional reaction. | Static result banner. |
| Long video refresh | Brief movement or question at safe checkpoint. | Optional small break prompt. | No interruption. |

## 10.4 Long-video rule

For content longer than thirty minutes, create refresh checkpoints near ten-minute intervals, but snap them to safe chapter boundaries. The player may pause and offer a stretch, recall question, or “ready to continue?” prompt. Students must be able to disable non-essential interruptions through Classroom Mode or accessibility settings. Content editors can remove or move checkpoints.

## 10.5 Generation quota controls

- Central quota service with per-day, per-school, and per-feature budgets.

- Hash the script, visual mode, language, and aspect ratio to reuse existing outputs.

- Generate in administration workflows, not at the moment a child opens a screen, unless explicitly approved.

- Store provenance, prompt version, provider, creation date, rights, and moderation result.

- Provide a deterministic local fallback for every generated asset slot.

# 11. Games Integration and Trusted XP

## 11.1 Game sourcing strategy

- Prefer maintained open-source games with clear commercial-use licenses and a simple integration surface.

- Use web games when they are responsive, keyboard/touch accessible, safe inside a restricted WebView, and reasonably small.

- Use Flutter-native games when deep device integration, offline support, or better performance justifies the effort.

- Do not accept a game solely because it is visually attractive. It must expose a verifiable start, end, score, duration, and version contract.

## 11.2 Game bridge contract

Nano -> Game
  session_started {session_id, game_version, signed_token, locale, settings}
  pause | resume | terminate

Game -> Nano
  ready
  progress {checkpoint}
  completed {session_id, raw_score, duration_ms, metrics, nonce}
  error {code}

Nano server
  verifies token, version, duration, boundaries, nonce, replay, policy
  stores result
  awards XP once
  returns verified_result

## 11.3 WebView security

- Allow only registered game origins or bundled local assets.

- Disable arbitrary navigation, popups, downloads, and unrestricted JavaScript interfaces.

- Expose a narrow typed bridge. Reject unknown message types and oversized payloads.

- Issue short-lived game tokens scoped to one user, one version, and one session.

- Never expose Supabase session tokens or service credentials to third-party game code when a narrower signed token can be used.

## 11.4 XP policy example

| Event | Relative reward | Controls |
| --- | --- | --- |
| Video completion | Low | One per published video version, completion threshold, daily cap. |
| Quiz attempt | None by itself | Avoid rewarding empty attempts. |
| Quiz score | Medium to high | Score bands, pass requirement, reduced repeat reward, one primary award per version. |
| Verified game result | Medium | Game-specific boundaries, duration, personal-best bonus, daily cap. |
| Achievement or mission | Optional bonus | Server-defined, source-event unique. |

# 12. Offline, Sync, Notifications, and Media

## 12.1 Offline support matrix

| Capability | Offline behavior | Server confirmation |
| --- | --- | --- |
| Student Home and records | Show cached read-only content with timestamp. | Refresh when connectivity returns. |
| Video | Provider-dependent; metadata and resume position can be cached. | Completion event must be validated. |
| Quiz | Resume locally saved answers within policy. | Final score and XP require trusted submit. |
| Attendance | Teacher may keep a local draft. | Submit or conflict resolution required. |
| Marks | Short-lived local draft only. | Publish requires server. |
| Game | Game may run if assets are available. | Result remains pending until verification. |
| Community message | Queue in later release. | Membership, block, and policy rechecked on send. |

## 12.2 Sync envelope

- operation_id: globally unique idempotency key.

- actor_id and active school context.

- module and operation type.

- target version or last-known revision.

- created_at and client clock metadata.

- payload checksum and schema version.

- retry count, last error, and visible status.

## 12.3 Notification delivery path

- A trusted domain event is created, such as assessment_published or friend_request_created.

- Notification policy resolves recipients, channel eligibility, quiet hours, and privacy-safe preview text.

- One logical inbox record is created per recipient using a source-event uniqueness key.

- Push delivery is attempted when permitted. Failure does not remove the in-app record.

- Deep links resolve through route and permission guards at open time.

## 12.4 Media storage policy

- Separate buckets or path prefixes for public approved content, school-private content, community media, user avatars, and generated companion assets.

- Private files use short-lived signed URLs and RLS-backed metadata checks.

- Uploads are staged until validation, malware scanning, and moderation status complete where applicable.

- Orphaned media cleanup runs from explicit retention rules, not a blind delete job.

# 13. Testing and Quality Gates

Nano needs more than UI screenshots. The testing strategy combines unit tests, widget and golden tests, integration tests, database policy tests, import fixtures, accessibility checks, and manual pilot scripts.

## 13.1 Test layers

| Layer | Covers | Examples |
| --- | --- | --- |
| Unit | Value objects, ViewModels, validators, mappers, XP rules, permission helpers. | Marks validation, quiz timer state, feature eligibility. |
| Widget | Screen behavior with fake repositories. | Loading, error, empty, submit disabled, accessibility labels. |
| Golden | Approved visual composition at fixed viewports. | Junior Home, Senior Quiz, teacher attendance row, web import preview. |
| Integration | Full user flow across widgets and services. | Sign in, watch video, take quiz, see result; teacher publish marks. |
| Database | Constraints, functions, transactions, and RLS. | School isolation, idempotent XP, assignment scope, publication rules. |
| Contract | External providers and internal bridge formats. | Game messages, video events, notification payloads. |
| Security | Abuse paths and privilege escalation. | Direct API calls, stale assignment, forged score, unsafe file upload. |

## 13.2 Required test identities

- Junior school-linked student in School A.

- Senior school-linked student in School A.

- Independent Senior student.

- Teacher assigned to one subject and one section in School A.

- Teacher in School A without the target assignment.

- School A manager.

- School B manager and students for cross-tenant attacks.

- Suspended user and user in suspended school.

- Platform content editor and platform security administrator with different privileges.

## 13.3 Module quality gate

- Analyzer and formatter pass.

- Unit and widget tests pass.

- Golden tests reviewed for all approved reference sizes.

- RLS and server-function tests pass for any owned table or mutation.

- Loading, empty, error, offline, permission, disabled, and suspended states are implemented where applicable.

- Analytics and audit events are documented and tested where required.

- No secrets, debug endpoints, unlicensed assets, or broad WebView bridges are present.

- Module README and MODULE_STATUS are current.

## 13.4 Manual pilot scripts

- New school setup from blank tenant to first student login.

- Teacher marks attendance with network interruption and retries.

- Teacher imports marks with valid and invalid rows, then publishes.

- Student watches a video, closes the app, resumes, completes, takes quiz, and receives XP once.

- School suspension while a user has an active session.

- Small-phone Urdu layout review.

- Screen reader and reduced-motion review for core student flows.

# 14. Cursor Operating Protocol

Cursor should operate from explicit module contracts, small tasks, tests, and reviewable commits. It should not infer the entire application from screenshots or make global architectural changes while implementing a single screen.

## 14.1 Root instructions for AGENTS.md

- Read this handbook, the target module README, MODULE_STATUS, and relevant architecture decisions before editing.

- Work only inside the named module and approved shared packages unless the task explicitly allows cross-module changes.

- Do not invent database tables, permissions, routes, design tokens, or analytics names when a contract exists.

- Never place service-role keys, provider secrets, or privileged logic in Flutter.

- Use fake repositories for UI tasks. Do not couple a screen directly to Supabase for speed.

- Add or update tests in the same task. A task is incomplete when only the happy path renders.

- Record assumptions and unresolved decisions rather than silently choosing incompatible behavior.

- Prefer small, reversible commits with one module outcome.

## 14.2 TASKS.md format

## [MODULE-ID] Task title
Status: todo | active | blocked | review | done
Release: R0 | R1 | R2 | R3 | R4
Goal: one observable outcome
Allowed paths:
Dependencies:
Inputs / reference images:
Acceptance criteria:
- [ ] ...
Required tests:
- [ ] unit
- [ ] widget/golden
- [ ] integration/RLS if applicable
Non-goals:
Risks / notes:
Evidence:
- screenshots
- test output
- migration IDs

## 14.3 Task size

- Good: “Build Junior subject card component with fixture states and golden tests.”

- Good: “Create attendance staging tables and validate one import template.”

- Bad: “Build the student portal.”

- Bad: “Connect everything to Supabase.”

- Bad: “Improve architecture across the project.”

## 14.4 UI implementation task sequence

- Create or confirm the state contract and fixtures.

- Build reusable components and the screen at the approved viewport.

- Add loading, empty, error, offline, disabled, and permission variants.

- Add semantics and responsive behavior.

- Create golden and widget tests.

- Review against reference image and record deviations.

- Only then connect the real repository in a separate task.

## 14.5 Backend implementation task sequence

- Write the domain operation and permission requirements.

- Design migration and constraints.

- Write RLS policies and policy tests before exposing the table.

- Implement database function or Edge Function for privileged mutation.

- Add idempotency, audit, and error codes.

- Implement repository adapter and contract tests.

- Connect ViewModel and run integration flow.

# 15. Implementation Roadmap

The roadmap below is dependency-driven. UI work can move slightly ahead using fixtures, but production integration should not skip foundation, tenancy, and server authority.

## 15.1 Phase sequence

| Phase | Theme | Deliverable |
| --- | --- | --- |
| Phase 0 | Repository intake | Copy demo1 into workspace, code audit, license scan, dependency map, choose state-management and routing packages. |
| Phase 1 | Foundation | FND-01, FND-02, FND-04, component gallery, app shells, fixtures, CI. |
| Phase 2 | Security and identity | SEC-01, FND-03, school creation, memberships, role guards, RLS adversarial tests. |
| Phase 3 | School structure | SCH-01, SCH-02, SCH-03, SCH-04, import staging and templates. |
| Phase 4 | Teacher academic core | TCH-01, ATT-01, MRK-01, CLS-01 with mobile-first entry and web administration. |
| Phase 5 | Student academic core | STU-01, STU-02, FLX-01, notifications, profile basics. |
| Phase 6 | Learning core | ADM-02, LRN-01, LRN-02, QZ-01, QZ-02, MED-01, basic CMP-01. |
| Phase 7 | Pilot hardening | Offline drafts, reports, audit review, accessibility, performance, support scripts, backup and restore drill. |
| Phase 8 | Engagement | Full GAM-01, GME-01, achievements, missions, leagues, share cards. |
| Phase 9 | Safety then social | SAFE-01 first, then SOC-01 and COM-01 behind school flags. |
| Phase 10 | Expansion | Guardian, structured feedback, payments/subscriptions, advanced recommendations and analytics. |

## 15.2 First pilot slice

- Create School A and its first administrator.

- Import one teacher and ten students.

- Create one class, one section, and two subjects. Assign the teacher.

- Teacher completes attendance and publishes one assessment.

- Superadmin publishes one Learning Stack subject with one topic, one video, and one ordered quiz.

- A Junior and Senior student complete the learning flow using different UI but the same backend rules.

- Verify published marks, attendance, quiz result, and XP isolation.

- Run School B cross-tenant tests and suspend School A to verify access removal.

## 15.3 Parallel workstreams

| Workstream | Can begin early | Must wait for |
| --- | --- | --- |
| Junior UI | Reference screens, design tokens, fixtures, golden tests. | Real data integration waits for repositories and auth. |
| Senior UI | Same as Junior. | Social data waits for safety and privacy contracts. |
| Teacher UI | Dashboard, attendance entry, marks entry fixtures. | Submission waits for assignments, RLS, and server functions. |
| Web portal | Shell, forms, import previews, content editor mock. | Commit actions wait for tenancy and migrations. |
| Companion assets | Static core set and local reaction system. | Generated API integration waits for quota, provenance, and fallback design. |
| Games research | License and bridge feasibility review. | Production release waits for score verification and kill switch. |

# 16. Deployment, Observability, and Operations

## 16.1 Environments

- Local: Supabase local stack, seeded schools and test identities, fake external providers.

- Development: shared integration environment with disposable data.

- Staging: production-like policies, release candidate builds, migration rehearsal, test notification credentials.

- Production: restricted access, protected secrets, backups, monitoring, and change approvals.

## 16.2 Release controls

- Feature flags by platform, school, grade, cohort, and account type.

- Remote kill switch for games and risky integrations.

- Backward-compatible client/server contracts during phased mobile rollout.

- Database migrations applied before clients that require them, with compatibility views when necessary.

- Store release notes map changes to module IDs and migrations.

## 16.3 Observability

| Area | Minimum signals |
| --- | --- |
| Client health | Crash-free sessions, startup failures, route failures, media playback errors, sync queue failures. |
| Backend health | Function error rate, latency, database saturation, failed jobs, RLS denial anomalies. |
| Product operation | School setup completion, attendance submission, marks publication, quiz completion, notification delivery. |
| Security | Suspicious logins, repeated denied access, forged score attempts, import abuse, moderation escalation. |
| Cost | Storage growth, egress, generated media usage, function execution, notification volume. |

## 16.4 Backup and recovery

- Document database backup and restoration capabilities for the selected Supabase plan.

- Export critical school data on a scheduled policy where required.

- Test restoration in a non-production environment before the pilot.

- Keep content assets and provenance records recoverable, not only database rows.

- Define recovery objectives for academic records, not just application uptime.

# 17. Risks, Decisions, and Change Control

## 17.1 Highest risks

| Risk | Why it matters | Mitigation |
| --- | --- | --- |
| Scope overload | The complete vision is much larger than a first release. | Release labels, dependency roadmap, one active vertical slice, feature flags. |
| Weak tenancy | A school data leak is unacceptable. | RLS-first schema, adversarial policy tests, least privilege, audited privileged functions. |
| AI-generated coupling | Cursor may duplicate logic or bypass boundaries for speed. | Module contracts, allowed paths, reviewable tasks, architecture linting, tests. |
| Companion API dependence | Free quotas and inconsistent output can break identity or availability. | Local core assets, controlled variants, cache, budget, deterministic fallback. |
| Untrusted game scores | Client or web game messages can be forged. | Signed sessions, narrow bridge, server verification, idempotent XP, kill switch. |
| Minor social safety | Communities and friends can create abuse and privacy risks. | Safety-gated release, school policy, block/report, moderation, rate limits, evidence controls. |
| Poor-network conflicts | Teachers may submit duplicate or stale academic data. | Idempotency, drafts, revision checks, conflict UI, correction history. |
| Unlicensed reuse | Assets or games may create legal exposure. | Provenance registry and release gate. |

## 17.2 Architecture decision records

Create a short ADR whenever a decision changes a cross-module contract. At minimum, record the context, options, selected decision, consequences, migration impact, and review date.

- ADR-001: Feature-first MVVM and package boundaries.

- ADR-002: Shared identity plus school memberships.

- ADR-003: RLS and server-authoritative scoring.

- ADR-004: Junior/Senior same domain, separate presentation.

- ADR-005: Companion asset ladder and controlled variants.

- ADR-006: Game host bridge and verification.

- ADR-007: Offline mutation limits and idempotency.

## 17.3 Change request rule

- Describe the user outcome and affected roles.

- Map affected modules, data, permissions, notifications, analytics, and release stage.

- Decide whether the request changes a public contract or only an internal implementation.

- Update this handbook or an ADR before large code changes.

- Add migration and backwards-compatibility plan when data or client contracts change.

# Appendix A. Core Data Model

This is a conceptual data dictionary, not final SQL. Final migrations should use consistent naming, timestamps, soft-archive fields where appropriate, constraints, indexes, RLS, and audit hooks.

| Domain | Core tables or records |
| --- | --- |
| Identity and tenancy | profiles, schools, school_memberships, platform_roles, device_sessions, login_events |
| Academic structure | academic_years, terms, grade_levels, classes, sections, school_subjects, class_subjects |
| People and scope | student_enrollments, teacher_assignments, guardian_links |
| Attendance | attendance_sessions, attendance_entries, attendance_corrections |
| Marks and results | assessments, assessment_versions, marks_entries, marks_corrections, grading_policies, result_periods, report_cards |
| Classroom | classroom_items, classroom_targets, classroom_attachments, acknowledgements |
| Learning Stack | learning_subjects, subject_versions, topics, topic_versions, content_assets, prerequisites, eligibility_rules, learning_progress |
| Video | video_assets, video_sessions, playback_progress, completion_events, refresh_checkpoints |
| Quiz | question_bank, question_versions, quiz_versions, quiz_items, quiz_policies, quiz_attempts, attempt_answers, score_results |
| Gamification | xp_ledger, level_rules, achievement_definitions, achievement_awards, missions, mission_progress, streaks, league_cycles, leaderboard_snapshots |
| Games | games, game_versions, game_assets, game_sessions, game_score_submissions, game_results, rejected_scores |
| Social | friend_requests, friendships, blocks, reports, challenges, challenge_results |
| Communities | communities, community_memberships, community_messages, message_reactions, community_reports, moderation_cases |
| Notifications | notification_templates, notification_events, inbox_items, device_tokens, notification_preferences, delivery_attempts |
| Billing and access | plans, subscriptions, entitlements, payment_events, access_periods |
| Operations | feature_flags, import_jobs, import_rows, audit_events, analytics_events, support_cases |
| Companion and media | companion_assets, companion_scripts, companion_events, generation_jobs, media_assets, media_provenance |

## A.1 Common columns

- id: stable UUID or suitable immutable identifier.

- school_id: required on school-owned records or securely derivable through a constrained relationship.

- created_at, updated_at, created_by, updated_by where meaningful.

- status and archived_at instead of destructive deletion for historical academic records.

- version or revision for mutable drafts and optimistic concurrency.

- source_event_id or idempotency_key for trusted repeated operations.

# Appendix B. Permissions Matrix

| Resource | Student | Teacher | School management | Superadmin | Guardian |
| --- | --- | --- | --- | --- | --- |
| Student private profile | Self | Limited assigned view | School admin | Platform safe view | Guardian limited linked view |
| Attendance | Own published record | Assigned entry/correction | School administration/report | Operational support only | Future linked summary |
| Draft marks | No | Assigned assessment | Authorized school admin | Privileged audited support | No |
| Published marks | Own | Assigned context | School admin | Privileged audited support | Future policy |
| Learning content | Eligible published | Published read | Published read | Create/publish by content role | Published read |
| Quiz score | Own | Aggregate if permitted | School aggregate where enabled | Operational/content audit | Future linked summary |
| XP and game history | Own and limited social | Limited class view if policy | Aggregate | Rules and investigation | Future summary |
| Communities | Senior policy | Teacher/member policy | School moderation | Platform moderation | No direct access |
| User suspension | No | No | School-scoped where authorized | Global authorized role | No |
| School suspension | No | No | No | Authorized platform role | No |

| Implementation note This matrix is a human-readable starting point. The authoritative permission specification must be executable through RLS tests and server-function tests. |
| --- |

# Appendix C. Definition of Done

- The user outcome is demonstrable from a clean build using documented test data.

- The module respects package boundaries and contains no direct cross-feature internal imports.

- Design matches approved references or deviations are recorded.

- Responsive, English/Urdu, text-scale, semantic-label, and reduced-motion checks pass where applicable.

- Loading, empty, error, retry, offline, permission, disabled, and suspended states exist where applicable.

- Unit, widget/golden, integration, database, and security tests required by the module pass.

- RLS is enabled and tested for every exposed table.

- Privileged mutations are server-authoritative, idempotent, and audited.

- No secrets, private keys, debug credentials, or service-role tokens are in the client or repository.

- Third-party code and assets have license and provenance records.

- Analytics, notifications, and audit events use documented names and avoid duplicates.

- Migrations and API contracts are documented and compatible with supported client versions.

- MODULE_STATUS and TASKS.md evidence are updated.

# Appendix D. Feature Traceability

| Source feature area | Implementation modules |
| --- | --- |
| Student authentication and onboarding | FND-03, STU-01 |
| Junior and Senior Home | STU-02, FND-02 |
| Learning Stack | LRN-01, ADM-02 |
| Video and post-video quiz | LRN-02, QZ-01, QZ-02, CMP-01 |
| Flex attendance, marks, Classroom | FLX-01, ATT-01, MRK-01, CLS-01 |
| Games and audio controls | GME-01, MED-01 |
| XP, levels, achievements, stickers, streaks | GAM-01 |
| Leagues and leaderboards | LGE-01 |
| Friends, challenges, sharing | SOC-01 |
| Communities | COM-01, SAFE-01 |
| Student and teacher profiles, settings, privacy, and device controls | PRF-01 |
| Notifications | NOT-01 |
| Nori and Aoede guide | CMP-01, MED-01 |
| Independent student experience | FND-04, STU modules with eligibility policies |
| Teacher dashboard and classes | TCH-01 |
| Teacher attendance and bulk upload | ATT-01 |
| Teacher assessments and bulk marks | MRK-01 |
| Teacher Classroom | CLS-01 |
| Teacher-parent feedback | FBK-01 |
| School dashboard, branding, structure, users, assignments | SCH-01 through SCH-04, ANL-01 |
| School result administration and reports | MRK-01, ANL-01 |
| Superadmin schools and users | ADM-01 |
| Superadmin Learning Stack and quizzes | ADM-02, QZ-01 |
| Superadmin gamification and games | GAM-01, GME-01 |
| Superadmin community safety | SAFE-01 |
| Superadmin notifications and analytics | NOT-01, ANL-01 |
| Independent trials, paid access, and expiry | BIL-01 |
| Guardian weekly material | PAR-01 |
| Multi-school, server authority, accessibility, weak network | SEC-01, FND-05, FND-02 |

# Appendix E. Reference Notes

Product source: the product owner’s complete Nano concept brief supplied with this task. The handbook resolves that brief into modules, sequencing, and implementation contracts.

Technical references consulted for architecture validation:

- Flutter: Guide to app architecture

- Flutter: Architecture recommendations and resources

- Flutter: Testing overview

- Supabase: Row Level Security

- Supabase: Securing data

- Supabase: Edge Functions

| Next project artifact After the existing code is copied into the active workspace, the next document should be the Existing Code Audit and a generated Phase 0 TASKS.md. Those two artifacts will turn this handbook into executable Cursor tasks. |
| --- |
