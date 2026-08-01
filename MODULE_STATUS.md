# MODULE_STATUS

Only one module may be `ACTIVE`. Owner marks approval via `NEXT`.

| ID | Name | Release | Status | Dependencies |
|----|------|---------|--------|--------------|
| AUD-01 | Repository and Security Audit | R0 | DONE | — |
| FND-01 | Workspace, Configuration, and Environments | R0 | DONE | AUD-01 |
| FND-02 | Shared Design System | R0 | DONE | FND-01 |
| FND-03 | Junior and Senior Responsive Foundations | R0 | DONE | FND-02 |
| FND-04 | Navigation and Role-Aware Application Shells | R0 | DONE | FND-03 |
| FND-05 | Error, Loading, Empty, Offline, and Maintenance States | R0 | DONE | FND-04 |
| FND-06 | Localization and English/Urdu Readiness | R0 | DONE | FND-02 |
| FND-07 | Accessibility, Sound, Haptics, and Reduced Motion | R0 | DONE | FND-02 |
| SEC-01 | Supabase Baseline and Migration Workflow | R0 | DONE | FND-01 |
| SEC-02 | Multi-School Tenancy and RLS | R0 | DONE | SEC-01 |
| SEC-03 | Audit Logs, Sessions, Suspension, and Permission Guards | R0 | DONE | SEC-02 |
| SYNC-01 | Local Cache, Drafts, Queue, and Conflict States | R0 | DONE | FND-05, SEC-01 |
| AUTH-01 | Student Authentication | R1 | DONE | SEC-03, FND-04 |
| AUTH-02 | Teacher Authentication | R1 | DONE | SEC-03, FND-04 |
| AUTH-03 | School Management and Superadmin Authentication | R1 | DONE | SEC-03, FND-04 |
| AUTH-04 | Independent Student Signup and Recovery | R1 | DONE | AUTH-01 |
| STU-01 | Student First-Run Onboarding | R1 | DONE | AUTH-01, FND-06, FND-07 |
| STU-02 | Nori Naming, Language, Sound, and Accessibility Setup | R1 | DONE | STU-01 |
| STU-03 | Junior Home | R2 | DONE | STU-02, FND-05 |
| STU-04 | Senior Home | R2 | DONE | STU-02, FND-05 |
| STU-05 | Student Profile and Settings | R2 | DONE | STU-03, STU-04 |
| STU-06 | Student Notifications Inbox | R2 | BACKLOG | STU-05 |
| LRN-01 | Learning Subject Catalog | R3 | DONE | STU-03, STU-04, SEC-02 |
| LRN-02 | Topic List, Ordering, and Prerequisites | R3 | DONE | LRN-01 |
| LRN-03 | Video Player, Resume, Captions, and Completion | R3 | DONE | LRN-02 |
| LRN-04 | Long-Video Checkpoints and Refresh Interactions | R3 | DONE | LRN-03 |
| LRN-05 | Learning Progress and Recommendations | R3 | DONE | LRN-03 |
| QZ-01 | Superadmin Question Bank | R3 | DONE | SEC-03 |
| QZ-02 | Video-Specific Ordered Quiz Authoring | R3 | DONE | QZ-01, LRN-02 |
| QZ-03 | Junior Quiz Experience | R3 | DONE | QZ-02, STU-03 |
| QZ-04 | Senior Quiz Experience | R3 | DONE | QZ-02, STU-04 |
| QZ-05 | Trusted Scoring, Attempts, Retakes, and Resume | R3 | DONE | QZ-03, QZ-04 |
| QZ-06 | Quiz Results, Explanations, and Progress Update | R3 | DONE | QZ-05 |
| CMP-01 | Nori Core Runtime | R4 | DONE | STU-02, FND-07 |
| CMP-02 | Nori Modes and Reaction Rules | R4 | DONE | CMP-01 |
| CMP-03 | Junior and Senior Companion Placement | R4 | DONE | CMP-02, STU-03, STU-04 |
| MED-01 | Generated Asset Provider Adapters | R4 | DONE | SEC-01, CMP-01 |
| MED-02 | Asset Caching, Hashing, Quotas, and Fallback | R4 | DONE | MED-01 |
| MED-03 | Voice Generation and Aoede Learning Guide | R4 | DONE | MED-02, CMP-01 |
| MED-04 | Video Generation and Reusable Reaction Library | R4 | DONE | MED-02, CMP-02 |
| MED-05 | Superadmin Asset Review and Publication | R4 | DONE | MED-02, ADM-01 |
| MED-06 | Fish Audio Narration and Composed Reaction Clips | R4 | DONE | MED-03, MED-04, MED-05 |
| MED-07 | Wan 2.2 Character Animation with Compose Fallback | R4 | DONE | MED-06 |
| MED-08 | Real Playback and Companion Art Rendering | R4 | DONE | MED-07, FND-07 |
| MED-09 | Nori Character Sheet and Static Pose Pack | R4 | DONE | MED-08 |
| MED-10 | Idle Life and Local Animation Tier | R4 | USER_TEST | MED-09 |
| MED-11 | Full Narration and Celebration Clip Pack | R4 | BACKLOG | MED-09 |
| MED-12 | Nori Everywhere and Companion Coverage Gate | R4 | BACKLOG | MED-10, MED-11 |
| XP-01 | Trusted XP Ledger | R5 | BACKLOG | SEC-02, AUTH-01 |
| XP-02 | Levels and Thresholds | R5 | BACKLOG | XP-01 |
| XP-03 | Achievements and Stickers | R5 | BACKLOG | XP-02 |
| XP-04 | Daily and Weekly Missions | R5 | BACKLOG | XP-01 |
| XP-05 | Streaks and Gentle Motivation | R5 | BACKLOG | XP-01, CMP-02 |
| XP-06 | Shareable Achievement and Score Cards | R5 | BACKLOG | XP-03 |
| ADM-01 | Superadmin Dashboard | R6 | BACKLOG | AUTH-03, FND-04 |
| ADM-02 | School Creation, Codes, Status, and Administrator Control | R6 | BACKLOG | ADM-01, SEC-02 |
| ADM-03 | Global User and Account Control | R6 | BACKLOG | ADM-01, SEC-03 |
| ADM-04 | Learning Stack Content Administration | R6 | BACKLOG | ADM-01, LRN-01 |
| ADM-05 | Gamification Administration | R6 | BACKLOG | ADM-01, XP-02 |
| ADM-06 | Game Administration | R6 | BACKLOG | ADM-01 |
| ADM-07 | Notification Administration | R6 | BACKLOG | ADM-01 |
| ADM-08 | Platform Analytics | R6 | BACKLOG | ADM-01 |
| SCH-01 | School Dashboard and Branding | R6 | BACKLOG | AUTH-03, SEC-02 |
| SCH-02 | Classes, Grades, Sections, and Subjects | R6 | BACKLOG | SCH-01 |
| SCH-03 | Teacher Management and Excel Import | R6 | BACKLOG | SCH-02 |
| SCH-04 | Student Management and Excel Import | R6 | BACKLOG | SCH-02 |
| SCH-05 | Teacher Assignment Matrix | R6 | BACKLOG | SCH-03, SCH-04 |
| SCH-06 | Marks and Result Policies | R6 | BACKLOG | SCH-01 |
| SCH-07 | School Reports | R6 | BACKLOG | SCH-05, SCH-06 |
| TCH-01 | Teacher Dashboard | R7 | BACKLOG | AUTH-02, SCH-05 |
| TCH-02 | My Classes and Assigned Scope | R7 | BACKLOG | TCH-01 |
| ATT-01 | In-App Attendance Grid | R7 | BACKLOG | TCH-02, SYNC-01 |
| ATT-02 | Attendance Excel Download and Upload | R7 | BACKLOG | ATT-01 |
| ATT-03 | Attendance Correction and History | R7 | BACKLOG | ATT-01 |
| MRK-01 | Assessment Creation | R7 | BACKLOG | TCH-02, SCH-06 |
| MRK-02 | In-App Marks Grid | R7 | BACKLOG | MRK-01, SYNC-01 |
| MRK-03 | Marks Excel Download and Upload | R7 | BACKLOG | MRK-02 |
| MRK-04 | Marks Publication and Correction | R7 | BACKLOG | MRK-02, SEC-03 |
| MRK-05 | Result and Class Performance Summary | R7 | BACKLOG | MRK-04 |
| CLS-01 | Teacher Classroom Announcements | R7 | BACKLOG | TCH-02 |
| CLS-02 | Classroom Materials and Attachments | R7 | BACKLOG | CLS-01, MED-02 |
| CLS-03 | Scheduling, Expiry, and Acknowledgement | R7 | BACKLOG | CLS-01 |
| FLX-01 | Student Flex Home | R7 | BACKLOG | STU-03, STU-04, AUTH-01 |
| FLX-02 | Student Attendance | R7 | BACKLOG | FLX-01, ATT-01 |
| FLX-03 | Student Marks and Results | R7 | BACKLOG | FLX-01, MRK-04 |
| FLX-04 | Student Classroom | R7 | BACKLOG | FLX-01, CLS-01 |
| FBK-01 | Teacher-Guardian Structured Feedback | R7 | BACKLOG | TCH-02 |
| GME-01 | Game Catalog and Eligibility | R8 | BACKLOG | STU-03, STU-04, XP-01 |
| GME-02 | Secure Web Game Container | R8 | BACKLOG | GME-01, SEC-03 |
| GME-03 | Open-Source Native Game Integration | R8 | BACKLOG | GME-01 |
| GME-04 | Game Download, Version, and Storage State | R8 | BACKLOG | GME-01 |
| GME-05 | Trusted Game Result Verification | R8 | BACKLOG | GME-02, XP-01 |
| GME-06 | Game Audio, Haptics, and Classroom Mode | R8 | BACKLOG | GME-01, FND-07 |
| GME-07 | Game Kill Switch and Version Disable | R8 | BACKLOG | GME-01, ADM-06 |
| LGE-01 | Weekly Leagues | R8 | BACKLOG | GME-05, XP-01 |
| LGE-02 | Leaderboards | R8 | BACKLOG | LGE-01 |
| LGE-03 | Challenges and Rematches | R8 | BACKLOG | LGE-02 |
| SOC-01 | Usernames, Friend Codes, and Limited Profiles | R9 | BACKLOG | STU-05, SEC-03 |
| SOC-02 | Friend Requests, Removal, and Blocking | R9 | BACKLOG | SOC-01 |
| SOC-03 | Friends Leaderboards | R9 | BACKLOG | SOC-02, LGE-02 |
| SOC-04 | Social Sharing | R9 | BACKLOG | SOC-01, XP-06 |
| COM-01 | Community Discovery | R9 | BACKLOG | STU-04, SAFE-01 |
| COM-02 | Community Creation and Roles | R9 | BACKLOG | COM-01 |
| COM-03 | Join Requests and Invitations | R9 | BACKLOG | COM-02 |
| COM-04 | Text Messages, Replies, Mentions, and Reactions | R9 | BACKLOG | COM-03, SAFE-03 |
| COM-05 | Voice Messages, Photos, Videos, and Files | R9 | BACKLOG | COM-04, MED-02, SAFE-02 |
| COM-06 | Pinned Messages, Search, Gallery, and Archives | R9 | BACKLOG | COM-04 |
| SAFE-01 | Reporting and Blocking | R9 | BACKLOG | SEC-03, STU-04 |
| SAFE-02 | Moderation Queue and Evidence | R9 | BACKLOG | SAFE-01, ADM-01 |
| SAFE-03 | Rate Limits, Restricted Content, and Link Rules | R9 | BACKLOG | SAFE-01 |
| SAFE-04 | School and Global Community Controls | R9 | BACKLOG | SAFE-02, SCH-01 |
| IND-01 | Independent Student Home and Natural Navigation | R10 | BACKLOG | STU-04, AUTH-04 |
| IND-02 | Independent Access Rules and Entitlements | R10 | BACKLOG | IND-01, SEC-03 |
| IND-03 | Trial, Free, and Paid States | R10 | BACKLOG | IND-02 |
| IND-04 | School Invitation and Account Linking | R10 | BACKLOG | IND-02, SCH-04 |
| PAR-01 | Weekly Parent Guidance Card | R10 | BACKLOG | STU-05 |
| PAR-02 | Superadmin Weekly PDF and Activity Upload | R10 | BACKLOG | PAR-01, ADM-01 |
| PAR-03 | Guardian Link Foundations | R10 | BACKLOG | PAR-01, AUTH-04 |
| NOT-01 | Push Delivery and Deep Links | R10 | BACKLOG | STU-06, FND-04 |
| NOT-02 | Quiet Hours, Category Controls, and Digest | R10 | BACKLOG | NOT-01 |
| ANA-01 | Product Analytics and School Health | R10 | BACKLOG | ADM-08, SCH-07 |
| QA-01 | Security Hardening | R10 | BACKLOG | SEC-03 |
| QA-02 | Performance and Small-Device Testing | R10 | BACKLOG | FND-03 |
| QA-03 | Offline and Poor-Network Testing | R10 | BACKLOG | SYNC-01 |
| QA-04 | Accessibility Audit | R10 | BACKLOG | FND-07 |
| QA-05 | Urdu and Bidirectional Layout Audit | R10 | BACKLOG | FND-06 |
| QA-06 | Pilot Release Preparation | R10 | BACKLOG | QA-01, QA-02, QA-03, QA-04, QA-05 |
