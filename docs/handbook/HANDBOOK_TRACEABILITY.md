# HANDBOOK_TRACEABILITY

Maps handbook requirements to automation modules. Automation queue is intentionally
more granular than handbook module IDs; no major handbook requirement is left unmapped.

Source: `docs/handbook/NANO_HANDBOOK.md` ← `Nano_Product_and_Implementation_Handbook_v1.0.docx`

| Handbook requirement | Module ID(s) | Application | Screen / service | Database responsibility | Test responsibility | Status |
|----------------------|--------------|-------------|------------------|-------------------------|----------------------|--------|
| 1.1 Product statement — Nano education platform | AUD-01 | all | N/A | N/A | docs review | IN_PROGRESS |
| 1.2 Product surfaces — student, teacher, school mgmt, superadmin | FND-04 | all apps | role shells | roles | shell tests | USER_TEST |
| 1.3 Account model — school vs independent students | AUTH-01,AUTH-04,IND-02 | student_app | auth/onboarding | profiles,school_id | auth/RLS | USER_TEST |
| 1.4 Non-negotiable rules — safety, tenancy, server authority | SEC-02,SEC-03,QA-01 | supabase | policies/functions | RLS | pgTAP | USER_TEST |
| 2.x Release strategy and pilot criteria | QA-06 | docs | pilot checklist | N/A | release checklist | BACKLOG |
| 3.1 Shared domain, separate shells | FND-04 | all apps | shells | N/A | widget | USER_TEST |
| 3.2 Junior interaction rules | FND-03,STU-03 | student_app | Junior Home | prefs | widget/golden | DONE |
| 3.3 Senior interaction rules | FND-03,STU-04 | student_app | Senior Home | prefs | widget/golden | DONE |
| 3.4 Teacher data-entry rules | TCH-01,ATT-01,MRK-02 | teacher_app | grids | attendance,marks | widget | BACKLOG |
| 3.5 Web administration rules | ADM-01,SCH-01 | admin_web | dashboards | schools | e2e | BACKLOG |
| 4.x Technical architecture / packages | FND-01 | packages | workspace | N/A | analyze | BACKLOG |
| 5.x Repository organization / feature folders | FND-01 | apps/packages | structure | N/A | structure check | BACKLOG |
| 6.1 Identity model | AUTH-01,AUTH-02,AUTH-03,AUTH-04 | nano_auth | session | auth.users,profiles | auth tests | USER_TEST |
| 6.2 Multi-school security | SEC-02 | supabase | RLS | school_id | two-school RLS | USER_TEST |
| 6.3 Trusted operations (scores, XP, publish) | QZ-05,XP-01,MRK-04,GME-05 | edge functions | scoring | ledgers | function tests | BACKLOG |
| 6.4 Versioning and history | SEC-03,MRK-04,ATT-03 | supabase | audit | audit_logs | history tests | BACKLOG |
| 7.x Reuse-first engineering | AUD-01 | docs/provenance | registry | N/A | docs | IN_PROGRESS |
| 8.1–8.2 UI-first / reference replication | FND-02,STU-03,STU-04 | student_app | UI | N/A | golden | BACKLOG |
| 8.3 Design tokens | FND-02 | nano_design_system | tokens | N/A | golden | BACKLOG |
| 8.4 Component families | FND-02 | nano_design_system | components | N/A | widget | BACKLOG |
| 8.5 Accessibility contract | FND-07,QA-04 | all apps | a11y | prefs | a11y tests | USER_TEST |
| Handbook FND-01 Workspace | FND-01 | workspace | config | env | CI | BACKLOG |
| Handbook FND-02 Design system shells | FND-02,FND-03 | design_system | shells | N/A | golden | BACKLOG |
| Handbook FND-03 Auth sessions roles | AUTH-01,AUTH-02,AUTH-03,AUTH-04,SEC-03 | nano_auth | auth | sessions | auth | USER_TEST |
| Handbook FND-04 Navigation deep links | FND-04,NOT-01 | apps | nav | N/A | nav tests | USER_TEST |
| Handbook SEC-01 Tenancy RLS audit | SEC-01,SEC-02,SEC-03 | supabase | RLS/audit | policies | pgTAP | USER_TEST |
| Handbook FND-05 Cache sync queue | SYNC-01 | packages | queue | local db | sync tests | BACKLOG |
| Handbook STU-01 Onboarding preferences | STU-01,STU-02 | student_app | onboarding | student_onboarding,student_preferences | widget | DONE |
| Handbook STU-02 Student Home | STU-03,STU-04 | student_app | Home | progress | widget | DONE |
| Handbook PRF-01 Profiles settings | STU-05 | student_app | Profile | privacy_settings,device_sessions | widget+SQL | DONE |
| Handbook LRN-01 Learning catalog | LRN-01 | student_app | Learning Stack | learning_subjects,subject_versions,topics,topic_versions,learning_catalog | unit+widget+SQL | DONE |
| Handbook LRN-01 topic order / prerequisites | LRN-02 | student_app | Topic detail + gates | topic_prerequisites,learning_progress,start_topic | unit+widget+SQL | DONE |
| Handbook LRN-02 Video learning progress | LRN-03 | student_app | Topic player | topic_versions,learning_progress,topic_completions,record_playback_heartbeat,complete_topic | unit+widget+SQL | DONE |
| Handbook LRN-02 refresh checkpoints | LRN-04 | student_app | player checkpoints | refresh_checkpoints,checkpoint_events,rebuild_refresh_checkpoints,acknowledge_checkpoint | unit+widget+SQL | DONE |
| Handbook LRN-01 progress + next recommendations | LRN-05 | student_app | Your progress + Continue Learning | learning_progress_summary,learning_next_up | unit+widget+SQL | DONE |
| Handbook QZ-01 Quiz authoring | QZ-01 | admin_web | question bank | questions,question_versions,question_bank,create_question_draft,publish_question_version | unit+widget+SQL | DONE |
| Handbook QZ-01 video quiz attachment | QZ-02 | admin_web | topic quizzes | quiz_versions,quiz_policies,quiz_items,quiz_authoring,learner_quiz | unit+widget+SQL | DONE |
| Handbook QZ-02 Junior quiz attempt UX | QZ-03 | student_app | Junior quiz | learner_quiz,JuniorQuizFlow | unit+widget | DONE |
| Handbook QZ-02 Senior quiz navigation | QZ-04 | student_app | Senior quiz | learner_quiz,SeniorQuizFlow | unit+widget | DONE |
| Handbook QZ-02 trusted scoring / resume | QZ-05 | student_app | quiz attempts | quiz_attempts,attempt_answers,score_results,submit_quiz_attempt | unit+widget+SQL | DONE |
| Handbook QZ-02 results, explanations, recommendations | QZ-06 | student_app | quiz results | topic_quiz_progress,learner_quiz_history,get_attempt_result,learning_next_up | unit+widget+SQL | DONE |
| Handbook QZ-02 Student quiz scoring | QZ-03,QZ-04,QZ-05,QZ-06 | student_app | quiz | attempts | scoring tests | DONE |
| Handbook FLX-01 Student Flex | FLX-01,FLX-02,FLX-03,FLX-04 | student_app | Flex | school data | RLS+UI | BACKLOG |
| Handbook TCH-01 Teacher dashboard | TCH-01,TCH-02 | teacher_app | Dashboard | assignments | scope tests | BACKLOG |
| Handbook ATT-01 Attendance | ATT-01,ATT-02,ATT-03 | teacher_app | Attendance grid | attendance | grid+excel | BACKLOG |
| Handbook MRK-01 Marks results | MRK-01,MRK-02,MRK-03,MRK-04,MRK-05 | teacher_app | Marks | assessments | publish rules | BACKLOG |
| Handbook CLS-01 Classroom | CLS-01,CLS-02,CLS-03 | teacher_app | Classroom | announcements | ack tests | BACKLOG |
| Handbook SCH-01 School setup branding | SCH-01 | admin_web | School dash | schools | branding | BACKLOG |
| Handbook SCH-02 Academic structure | SCH-02 | admin_web | Classes | classes | structure | BACKLOG |
| Handbook SCH-03 Users imports enrollment | SCH-03,SCH-04 | admin_web | Imports | users | excel import | BACKLOG |
| Handbook SCH-04 Teacher assignment | SCH-05 | admin_web | Assignment matrix | assignments | matrix | BACKLOG |
| Handbook ADM-01 Global school accounts | ADM-01,ADM-02,ADM-03 | admin_web | Superadmin | schools,users | admin | BACKLOG |
| Handbook ADM-02 Learning content admin | ADM-04 | admin_web | Content admin | content | admin | BACKLOG |
| Handbook GME-01 Games secure host | GME-01,GME-02,GME-05,GME-07 | student_app | Games | game_sessions | verify score | BACKLOG |
| Handbook SOC-01 Friends challenges sharing | SOC-01,SOC-02,SOC-03,SOC-04,LGE-03 | student_app | Social | friends | social+block | BACKLOG |
| Handbook COM-01 Senior Communities | COM-01..COM-06 | student_app | Communities | communities | junior exclusion | BACKLOG |
| Handbook SAFE-01 Community safety | SAFE-01,SAFE-02,SAFE-03,SAFE-04 | admin+student | moderation | reports | safety | BACKLOG |
| Handbook CMP-01 Nori companion | CMP-01 | student_app | Nori reactions on quiz results + gallery | CompanionRuntime,CompanionStage (no DB) | unit+widget | DONE |
| Handbook 10.1 controlled variants and reaction rules | CMP-02 | student_app | Nori modes, story cards | CompanionMode,CompanionRules (no DB) | unit+widget | DONE |
| Handbook CMP-01 companion placement and enrichment | CMP-03 | student_app | Nori on home, learning, progress at junior/senior density | CompanionPlacement,CompanionController (no DB) | unit+widget | DONE |
| Handbook 10.2/10.5 generated asset adapters, hashing, provenance | MED-01 | edge+packages | none (server module) | generation_providers,generated_assets,generation_attempts | SQL+unit | DONE |
| Handbook MED-01 Media asset delivery | MED-03,MED-04,MED-05 | edge+admin | providers | generated_assets | quota/hash | PARTIAL |
| Handbook NOT-01 Notifications inbox | STU-06,NOT-01,NOT-02,ADM-07 | student_app | Inbox | notifications | push/deeplink | BACKLOG |
| Handbook PAR-01 Guardian guidance | PAR-01,PAR-02,PAR-03,FBK-01 | student+admin | Parent card | guidance | guardian | BACKLOG |
| XP rules — video/quiz/games XP; no marks/attendance XP | XP-01..XP-06 | edge | ledger | xp_ledger | idempotency | BACKLOG |
| Junior must not see Communities | COM-01,SAFE-04,STU-03 | student_app | nav guard | roles | junior nav test | BACKLOG |
| Independent students — natural experience, no empty Flex | IND-01,IND-02,IND-03,IND-04 | student_app | Independent Home | entitlements | nav tests | BACKLOG |
| English/Urdu readiness | FND-06,QA-05 | all apps | l10n | locale prefs | bidi audit | USER_TEST |
| Generated media cost controls | MED-02 | edge+student_app | budgets, cached delivery, local fallback | generation_quotas,generation_usage,generated_assets | SQL+unit+widget | DONE |
| Nori voice Aoede; no privileged calc | MED-03,CMP-01 | edge+app | narration lines, Aoede registry, caption-first Listen | narration_voices,narration_lines,narration_line_versions,generated_assets | SQL+unit+widget | DONE |
| Reusable reaction clips; silent optional motion | MED-04,CMP-02 | edge+app | reaction clip library, async Veo, per-slot availability | reaction_clips,reaction_clip_versions,generated_assets | SQL+unit+widget | DONE |
| Generated assets reviewed before a learner sees them; publication is a named decision | MED-05 | admin_web | Moderation queue, preview, approve/reject, history | asset_review_events,generated_assets | SQL+unit+widget | DONE |
| Narration and reaction clips through the chosen providers | MED-06 | edge+packages+admin_web | Moderation plays voice and video | generation_providers,narration_voices,reaction_clip_versions | SQL+Deno+widget | DONE |
| Character animation of approved companion art | MED-07 | edge+packages | Moderation reviews Wan clips | generation_providers | SQL+Deno | DONE |
| Approved media finally reaches a child; nothing plays unasked | MED-08 | student_app+packages | companion art, Listen, Play clip, real topic playback | none | widget+unit | DONE |
| Nori is one recognisable character in every pose | MED-09 | packages+student_app | bundled offline art, approved pose pack | generated_assets,companion_character_sheet | SQL+widget | DONE |
| A companion that looks alive costs nothing to run | MED-10 | packages+student_app | breathing, bob, mood motion | none | widget | DONE |
| A line for every moment, a clip for the big ones | MED-11 | edge+packages | narration and celebration coverage | narration_lines,reaction_clips | SQL+unit | DONE |
| Nori is present wherever the policy says, and the gap is visible | MED-12 | student_app+admin_web | full placement, coverage report | none | domain+widget | ACTIVE |
| Long video checkpoints ~10 min | LRN-04 | student_app | player checkpoints | refresh_checkpoints,checkpoint_events | checkpoint tests | DONE |
| School reports / analytics | SCH-07,ADM-08,ANA-01 | admin_web | reports | analytics | report tests | BACKLOG |
| Marks/attendance Excel flows | ATT-02,MRK-03,SCH-03,SCH-04 | teacher+admin | excel | imports | parse tests | BACKLOG |
| Offline / poor network | SYNC-01,QA-03,FND-05 | apps | offline states | queue | offline tests | USER_TEST |
| Pilot release preparation | QA-06 | all | checklist | N/A | gate | BACKLOG |

## Coverage statement

- Mapped requirement rows: **64**
- Handbook catalog modules (FND/SEC/STU/…): each appears in at least one row
- Master automation queue (120 modules): each release feature is reachable from a handbook row
- Status values: BACKLOG | IN_PROGRESS | DONE

## Unmapped check

If a new handbook section is added, append a row before marking any related module DONE.
