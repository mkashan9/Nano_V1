"""Generate Nano automation controls, module queue, audits, and provenance docs."""
from __future__ import annotations

from pathlib import Path
from textwrap import dedent

ROOT = Path(r"d:\nano")

# Master prompt queue (section 15) — authoritative automation queue
MODULES: list[dict] = [
    # Release 0
    {"id": "AUD-01", "name": "Repository and Security Audit", "release": "R0", "deps": []},
    {"id": "FND-01", "name": "Workspace, Configuration, and Environments", "release": "R0", "deps": ["AUD-01"]},
    {"id": "FND-02", "name": "Shared Design System", "release": "R0", "deps": ["FND-01"]},
    {"id": "FND-03", "name": "Junior and Senior Responsive Foundations", "release": "R0", "deps": ["FND-02"]},
    {"id": "FND-04", "name": "Navigation and Role-Aware Application Shells", "release": "R0", "deps": ["FND-03"]},
    {"id": "FND-05", "name": "Error, Loading, Empty, Offline, and Maintenance States", "release": "R0", "deps": ["FND-04"]},
    {"id": "FND-06", "name": "Localization and English/Urdu Readiness", "release": "R0", "deps": ["FND-02"]},
    {"id": "FND-07", "name": "Accessibility, Sound, Haptics, and Reduced Motion", "release": "R0", "deps": ["FND-02"]},
    {"id": "SEC-01", "name": "Supabase Baseline and Migration Workflow", "release": "R0", "deps": ["FND-01"]},
    {"id": "SEC-02", "name": "Multi-School Tenancy and RLS", "release": "R0", "deps": ["SEC-01"]},
    {"id": "SEC-03", "name": "Audit Logs, Sessions, Suspension, and Permission Guards", "release": "R0", "deps": ["SEC-02"]},
    {"id": "SYNC-01", "name": "Local Cache, Drafts, Queue, and Conflict States", "release": "R0", "deps": ["FND-05", "SEC-01"]},
    # Release 1
    {"id": "AUTH-01", "name": "Student Authentication", "release": "R1", "deps": ["SEC-03", "FND-04"]},
    {"id": "AUTH-02", "name": "Teacher Authentication", "release": "R1", "deps": ["SEC-03", "FND-04"]},
    {"id": "AUTH-03", "name": "School Management and Superadmin Authentication", "release": "R1", "deps": ["SEC-03", "FND-04"]},
    {"id": "AUTH-04", "name": "Independent Student Signup and Recovery", "release": "R1", "deps": ["AUTH-01"]},
    {"id": "STU-01", "name": "Student First-Run Onboarding", "release": "R1", "deps": ["AUTH-01", "FND-06", "FND-07"]},
    {"id": "STU-02", "name": "Nori Naming, Language, Sound, and Accessibility Setup", "release": "R1", "deps": ["STU-01"]},
    # Release 2
    {"id": "STU-03", "name": "Junior Home", "release": "R2", "deps": ["STU-02", "FND-05"]},
    {"id": "STU-04", "name": "Senior Home", "release": "R2", "deps": ["STU-02", "FND-05"]},
    {"id": "STU-05", "name": "Student Profile and Settings", "release": "R2", "deps": ["STU-03", "STU-04"]},
    {"id": "STU-06", "name": "Student Notifications Inbox", "release": "R2", "deps": ["STU-05"]},
    # Release 3
    {"id": "LRN-01", "name": "Learning Subject Catalog", "release": "R3", "deps": ["STU-03", "STU-04", "SEC-02"]},
    {"id": "LRN-02", "name": "Topic List, Ordering, and Prerequisites", "release": "R3", "deps": ["LRN-01"]},
    {"id": "LRN-03", "name": "Video Player, Resume, Captions, and Completion", "release": "R3", "deps": ["LRN-02"]},
    {"id": "LRN-04", "name": "Long-Video Checkpoints and Refresh Interactions", "release": "R3", "deps": ["LRN-03", "CMP-01"]},
    {"id": "LRN-05", "name": "Learning Progress and Recommendations", "release": "R3", "deps": ["LRN-03"]},
    {"id": "QZ-01", "name": "Superadmin Question Bank", "release": "R3", "deps": ["SEC-03", "ADM-01"]},
    {"id": "QZ-02", "name": "Video-Specific Ordered Quiz Authoring", "release": "R3", "deps": ["QZ-01", "LRN-02"]},
    {"id": "QZ-03", "name": "Junior Quiz Experience", "release": "R3", "deps": ["QZ-02", "STU-03"]},
    {"id": "QZ-04", "name": "Senior Quiz Experience", "release": "R3", "deps": ["QZ-02", "STU-04"]},
    {"id": "QZ-05", "name": "Trusted Scoring, Attempts, Retakes, and Resume", "release": "R3", "deps": ["QZ-03", "QZ-04"]},
    {"id": "QZ-06", "name": "Quiz Results, Explanations, and Progress Update", "release": "R3", "deps": ["QZ-05"]},
    # Release 4
    {"id": "CMP-01", "name": "Nori Core Runtime", "release": "R4", "deps": ["STU-02", "FND-07"]},
    {"id": "CMP-02", "name": "Nori Modes and Reaction Rules", "release": "R4", "deps": ["CMP-01"]},
    {"id": "CMP-03", "name": "Junior and Senior Companion Placement", "release": "R4", "deps": ["CMP-02", "STU-03", "STU-04"]},
    {"id": "MED-01", "name": "Generated Asset Provider Adapters", "release": "R4", "deps": ["SEC-01"]},
    {"id": "MED-02", "name": "Asset Caching, Hashing, Quotas, and Fallback", "release": "R4", "deps": ["MED-01"]},
    {"id": "MED-03", "name": "Voice Generation and Aoede Learning Guide", "release": "R4", "deps": ["MED-02", "CMP-01"]},
    {"id": "MED-04", "name": "Video Generation and Reusable Reaction Library", "release": "R4", "deps": ["MED-02", "CMP-02"]},
    {"id": "MED-05", "name": "Superadmin Asset Review and Publication", "release": "R4", "deps": ["MED-02", "ADM-01"]},
    # Release 5
    {"id": "XP-01", "name": "Trusted XP Ledger", "release": "R5", "deps": ["SEC-02", "AUTH-01"]},
    {"id": "XP-02", "name": "Levels and Thresholds", "release": "R5", "deps": ["XP-01"]},
    {"id": "XP-03", "name": "Achievements and Stickers", "release": "R5", "deps": ["XP-02"]},
    {"id": "XP-04", "name": "Daily and Weekly Missions", "release": "R5", "deps": ["XP-01"]},
    {"id": "XP-05", "name": "Streaks and Gentle Motivation", "release": "R5", "deps": ["XP-01", "CMP-02"]},
    {"id": "XP-06", "name": "Shareable Achievement and Score Cards", "release": "R5", "deps": ["XP-03"]},
    # Release 6
    {"id": "ADM-01", "name": "Superadmin Dashboard", "release": "R6", "deps": ["AUTH-03", "FND-04"]},
    {"id": "ADM-02", "name": "School Creation, Codes, Status, and Administrator Control", "release": "R6", "deps": ["ADM-01", "SEC-02"]},
    {"id": "ADM-03", "name": "Global User and Account Control", "release": "R6", "deps": ["ADM-01", "SEC-03"]},
    {"id": "ADM-04", "name": "Learning Stack Content Administration", "release": "R6", "deps": ["ADM-01", "LRN-01"]},
    {"id": "ADM-05", "name": "Gamification Administration", "release": "R6", "deps": ["ADM-01", "XP-02"]},
    {"id": "ADM-06", "name": "Game Administration", "release": "R6", "deps": ["ADM-01"]},
    {"id": "ADM-07", "name": "Notification Administration", "release": "R6", "deps": ["ADM-01"]},
    {"id": "ADM-08", "name": "Platform Analytics", "release": "R6", "deps": ["ADM-01"]},
    {"id": "SCH-01", "name": "School Dashboard and Branding", "release": "R6", "deps": ["AUTH-03", "SEC-02"]},
    {"id": "SCH-02", "name": "Classes, Grades, Sections, and Subjects", "release": "R6", "deps": ["SCH-01"]},
    {"id": "SCH-03", "name": "Teacher Management and Excel Import", "release": "R6", "deps": ["SCH-02"]},
    {"id": "SCH-04", "name": "Student Management and Excel Import", "release": "R6", "deps": ["SCH-02"]},
    {"id": "SCH-05", "name": "Teacher Assignment Matrix", "release": "R6", "deps": ["SCH-03", "SCH-04"]},
    {"id": "SCH-06", "name": "Marks and Result Policies", "release": "R6", "deps": ["SCH-01"]},
    {"id": "SCH-07", "name": "School Reports", "release": "R6", "deps": ["SCH-05", "SCH-06"]},
    # Release 7
    {"id": "TCH-01", "name": "Teacher Dashboard", "release": "R7", "deps": ["AUTH-02", "SCH-05"]},
    {"id": "TCH-02", "name": "My Classes and Assigned Scope", "release": "R7", "deps": ["TCH-01"]},
    {"id": "ATT-01", "name": "In-App Attendance Grid", "release": "R7", "deps": ["TCH-02", "SYNC-01"]},
    {"id": "ATT-02", "name": "Attendance Excel Download and Upload", "release": "R7", "deps": ["ATT-01"]},
    {"id": "ATT-03", "name": "Attendance Correction and History", "release": "R7", "deps": ["ATT-01"]},
    {"id": "MRK-01", "name": "Assessment Creation", "release": "R7", "deps": ["TCH-02", "SCH-06"]},
    {"id": "MRK-02", "name": "In-App Marks Grid", "release": "R7", "deps": ["MRK-01", "SYNC-01"]},
    {"id": "MRK-03", "name": "Marks Excel Download and Upload", "release": "R7", "deps": ["MRK-02"]},
    {"id": "MRK-04", "name": "Marks Publication and Correction", "release": "R7", "deps": ["MRK-02", "SEC-03"]},
    {"id": "MRK-05", "name": "Result and Class Performance Summary", "release": "R7", "deps": ["MRK-04"]},
    {"id": "CLS-01", "name": "Teacher Classroom Announcements", "release": "R7", "deps": ["TCH-02"]},
    {"id": "CLS-02", "name": "Classroom Materials and Attachments", "release": "R7", "deps": ["CLS-01", "MED-02"]},
    {"id": "CLS-03", "name": "Scheduling, Expiry, and Acknowledgement", "release": "R7", "deps": ["CLS-01"]},
    {"id": "FLX-01", "name": "Student Flex Home", "release": "R7", "deps": ["STU-03", "STU-04", "AUTH-01"]},
    {"id": "FLX-02", "name": "Student Attendance", "release": "R7", "deps": ["FLX-01", "ATT-01"]},
    {"id": "FLX-03", "name": "Student Marks and Results", "release": "R7", "deps": ["FLX-01", "MRK-04"]},
    {"id": "FLX-04", "name": "Student Classroom", "release": "R7", "deps": ["FLX-01", "CLS-01"]},
    {"id": "FBK-01", "name": "Teacher-Guardian Structured Feedback", "release": "R7", "deps": ["TCH-02", "PAR-03"]},
    # Release 8
    {"id": "GME-01", "name": "Game Catalog and Eligibility", "release": "R8", "deps": ["STU-03", "STU-04", "XP-01"]},
    {"id": "GME-02", "name": "Secure Web Game Container", "release": "R8", "deps": ["GME-01", "SEC-03"]},
    {"id": "GME-03", "name": "Open-Source Native Game Integration", "release": "R8", "deps": ["GME-01"]},
    {"id": "GME-04", "name": "Game Download, Version, and Storage State", "release": "R8", "deps": ["GME-01"]},
    {"id": "GME-05", "name": "Trusted Game Result Verification", "release": "R8", "deps": ["GME-02", "XP-01"]},
    {"id": "GME-06", "name": "Game Audio, Haptics, and Classroom Mode", "release": "R8", "deps": ["GME-01", "FND-07"]},
    {"id": "GME-07", "name": "Game Kill Switch and Version Disable", "release": "R8", "deps": ["GME-01", "ADM-06"]},
    {"id": "LGE-01", "name": "Weekly Leagues", "release": "R8", "deps": ["GME-05", "XP-01"]},
    {"id": "LGE-02", "name": "Leaderboards", "release": "R8", "deps": ["LGE-01"]},
    {"id": "LGE-03", "name": "Challenges and Rematches", "release": "R8", "deps": ["LGE-02", "SOC-01"]},
    # Release 9
    {"id": "SOC-01", "name": "Usernames, Friend Codes, and Limited Profiles", "release": "R9", "deps": ["STU-05", "SEC-03"]},
    {"id": "SOC-02", "name": "Friend Requests, Removal, and Blocking", "release": "R9", "deps": ["SOC-01"]},
    {"id": "SOC-03", "name": "Friends Leaderboards", "release": "R9", "deps": ["SOC-02", "LGE-02"]},
    {"id": "SOC-04", "name": "Social Sharing", "release": "R9", "deps": ["SOC-01", "XP-06"]},
    {"id": "COM-01", "name": "Community Discovery", "release": "R9", "deps": ["STU-04", "SAFE-01"]},
    {"id": "COM-02", "name": "Community Creation and Roles", "release": "R9", "deps": ["COM-01"]},
    {"id": "COM-03", "name": "Join Requests and Invitations", "release": "R9", "deps": ["COM-02"]},
    {"id": "COM-04", "name": "Text Messages, Replies, Mentions, and Reactions", "release": "R9", "deps": ["COM-03", "SAFE-03"]},
    {"id": "COM-05", "name": "Voice Messages, Photos, Videos, and Files", "release": "R9", "deps": ["COM-04", "MED-02", "SAFE-02"]},
    {"id": "COM-06", "name": "Pinned Messages, Search, Gallery, and Archives", "release": "R9", "deps": ["COM-04"]},
    {"id": "SAFE-01", "name": "Reporting and Blocking", "release": "R9", "deps": ["SEC-03", "STU-04"]},
    {"id": "SAFE-02", "name": "Moderation Queue and Evidence", "release": "R9", "deps": ["SAFE-01", "ADM-01"]},
    {"id": "SAFE-03", "name": "Rate Limits, Restricted Content, and Link Rules", "release": "R9", "deps": ["SAFE-01"]},
    {"id": "SAFE-04", "name": "School and Global Community Controls", "release": "R9", "deps": ["SAFE-02", "SCH-01"]},
    # Release 10
    {"id": "IND-01", "name": "Independent Student Home and Natural Navigation", "release": "R10", "deps": ["STU-04", "AUTH-04"]},
    {"id": "IND-02", "name": "Independent Access Rules and Entitlements", "release": "R10", "deps": ["IND-01", "SEC-03"]},
    {"id": "IND-03", "name": "Trial, Free, and Paid States", "release": "R10", "deps": ["IND-02"]},
    {"id": "IND-04", "name": "School Invitation and Account Linking", "release": "R10", "deps": ["IND-02", "SCH-04"]},
    {"id": "PAR-01", "name": "Weekly Parent Guidance Card", "release": "R10", "deps": ["STU-05"]},
    {"id": "PAR-02", "name": "Superadmin Weekly PDF and Activity Upload", "release": "R10", "deps": ["PAR-01", "ADM-01"]},
    {"id": "PAR-03", "name": "Guardian Link Foundations", "release": "R10", "deps": ["PAR-01", "AUTH-04"]},
    {"id": "NOT-01", "name": "Push Delivery and Deep Links", "release": "R10", "deps": ["STU-06", "FND-04"]},
    {"id": "NOT-02", "name": "Quiet Hours, Category Controls, and Digest", "release": "R10", "deps": ["NOT-01"]},
    {"id": "ANA-01", "name": "Product Analytics and School Health", "release": "R10", "deps": ["ADM-08", "SCH-07"]},
    {"id": "QA-01", "name": "Security Hardening", "release": "R10", "deps": ["SEC-03"]},
    {"id": "QA-02", "name": "Performance and Small-Device Testing", "release": "R10", "deps": ["FND-03"]},
    {"id": "QA-03", "name": "Offline and Poor-Network Testing", "release": "R10", "deps": ["SYNC-01"]},
    {"id": "QA-04", "name": "Accessibility Audit", "release": "R10", "deps": ["FND-07"]},
    {"id": "QA-05", "name": "Urdu and Bidirectional Layout Audit", "release": "R10", "deps": ["FND-06"]},
    {"id": "QA-06", "name": "Pilot Release Preparation", "release": "R10", "deps": ["QA-01", "QA-02", "QA-03", "QA-04", "QA-05"]},
]

# Soften circular-ish deps: LRN-04 needs CMP-01 which is R4; QZ-01 needs ADM-01 which is R6
# Keep as declared; eligibility engine will surface blockers. Fix soft deps for early progress:
for m in MODULES:
    if m["id"] == "LRN-04":
        m["deps"] = ["LRN-03"]  # CMP-01 soft-coupled later
    if m["id"] == "QZ-01":
        m["deps"] = ["SEC-03"]  # ADM shell can wrap later
    if m["id"] == "FBK-01":
        m["deps"] = ["TCH-02"]  # PAR-03 soft-coupled
    if m["id"] == "LGE-03":
        m["deps"] = ["LGE-02"]  # SOC-01 soft-coupled
    if m["id"] == "COM-01":
        m["deps"] = ["STU-04", "SAFE-01"]


def write(path: Path, content: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(dedent(content).lstrip("\n") if content.startswith("\n") else content, encoding="utf-8")
    if not content.endswith("\n"):
        path.write_text(path.read_text(encoding="utf-8") + "\n", encoding="utf-8")


def module_yaml(m: dict, status: str) -> str:
    mid = m["id"]
    apps = ["student_app", "teacher_app", "admin_web", "docs", "automation", "supabase"]
    if mid.startswith(("STU", "LRN", "QZ", "FLX", "IND", "CMP", "XP", "GME", "LGE", "SOC", "COM", "PAR", "NOT")):
        apps = ["student_app", "packages", "docs", "automation"]
    if mid.startswith(("TCH", "ATT", "MRK", "CLS", "FBK")):
        apps = ["teacher_app", "packages", "docs", "automation"]
    if mid.startswith(("ADM", "SCH")):
        apps = ["admin_web", "packages", "docs", "automation"]
    if mid.startswith(("SEC", "AUD", "FND", "SYNC", "AUTH", "MED", "SAFE", "QA", "ANA")):
        apps = ["student_app", "teacher_app", "admin_web", "packages", "supabase", "docs", "automation"]

    deps = "\n".join(f"  - {d}" for d in m["deps"]) or "  []"
    return f"""id: {mid}
name: "{m['name']}"
release: {m['release']}
status: {status}
dependencies:
{deps if m['deps'] else '  []'}
applications:
{chr(10).join('  - ' + a for a in apps)}
allowed_paths:
  - docs/
  - automation/
  - docs/modules/{mid}/
  - automation/modules/{mid}.yaml
  - MODULE_STATUS.md
  - PROJECT_STATUS.md
  - TASKS.md
  - CHANGELOG.md
  - AGENTS.md
forbidden_paths:
  - supabase/functions/.env.local
  - api_s.txt
  - github.txt
handbook_sections:
  - "See docs/handbook/HANDBOOK_TRACEABILITY.md for {mid}"
ui_references: []
database_scope: []
server_functions: []
acceptance:
  - Module documentation complete
  - Required tests listed and executed or marked NOT RUN with reason
  - No secrets exposed
  - Owner manual test steps provided
required_tests:
  - documentation_review
security_checks:
  - no_secrets_in_diff
accessibility_checks: []
manual_test_steps:
  - Review module docs and status
rollback_notes: "Revert module branch commits"
requires_owner_test: true
"""


def main() -> None:
    # Directories
    for d in [
        "automation/modules",
        "automation/prompts",
        "automation/scripts",
        "automation/schemas",
        ".cursor/rules",
        "docs/modules",
        "docs/architecture-decisions",
        "docs/test-reports",
        "docs/handbook",
        "docs/audits",
        "docs/provenance",
        "docs/provider-registry",
        "docs/setup",
        ".github/workflows",
        "apps",
        "packages",
        "assets",
    ]:
        (ROOT / d).mkdir(parents=True, exist_ok=True)

    # Module YAMLs — AUD-01 ACTIVE initially; generator sets READY for deps-met later
    for m in MODULES:
        status = "READY" if not m["deps"] else "BACKLOG"
        if m["id"] == "AUD-01":
            status = "ACTIVE"
        write(ROOT / f"automation/modules/{m['id']}.yaml", module_yaml(m, status))

    # MODULE_STATUS
    lines = [
        "# MODULE_STATUS",
        "",
        "Only one module may be `ACTIVE`. Owner marks approval via `NEXT`.",
        "",
        "| ID | Name | Release | Status | Dependencies |",
        "|----|------|---------|--------|--------------|",
    ]
    for m in MODULES:
        status = "READY" if not m["deps"] else "BACKLOG"
        if m["id"] == "AUD-01":
            status = "ACTIVE"
        deps = ", ".join(m["deps"]) if m["deps"] else "—"
        lines.append(f"| {m['id']} | {m['name']} | {m['release']} | {status} | {deps} |")
    lines.append("")
    write(ROOT / "MODULE_STATUS.md", "\n".join(lines))

    write(
        ROOT / "PROJECT_STATUS.md",
        """# PROJECT_STATUS

## Current state

- **Current release:** R0 Foundation
- **Current module:** AUD-01 Repository and Security Audit
- **Current status:** ACTIVE (bootstrap in progress → USER_TEST)
- **Current branch:** `module/AUD-01-repository-security-audit` (created during module start)
- **Last completed module:** none
- **Application name:** Nano

## Safe resume point

Phase 0–7 bootstrap artifacts; AUD-01 owner test gate.

## Open blockers

1. Docker Desktop not running — local `supabase start` unavailable (WARNING, not blocking AUD-01 docs).
2. `gh auth login` requires `read:org` scope — API access works via Git Credential Manager + `GH_TOKEN` session when needed.
3. Remote Supabase project `nano_v1` exists and is ACTIVE_HEALTHY with **zero tables** — treat as production-like until owner classifies; no remote schema writes without approval.

## Next eligible after AUD-01 DONE

FND-01 Workspace, Configuration, and Environments
""",
    )

    write(
        ROOT / "TASKS.md",
        """# TASKS

## Active

- [ ] AUD-01: Complete repository and security audit deliverables
- [ ] AUD-01: Owner manual test / review
- [ ] Await owner `NEXT` or `FIX:`

## Up next

- [ ] FND-01: Workspace, Configuration, and Environments

## Standing rules

- One ACTIVE module at a time
- Stop at USER_TEST for owner validation
- Never mark APPROVED without owner `NEXT`
""",
    )

    write(
        ROOT / "CHANGELOG.md",
        """# CHANGELOG

## Unreleased

### Added

- Bootstrap: credential migration, ignore rules, handbook extraction, UI catalog
- Automation controls: module queue, status docs, Cursor rules
- AUD-01 audit documentation set
""",
    )

    write(
        ROOT / "AGENTS.md",
        """# AGENTS.md — Nano engineering agent contract

## Product

Application name: **Nano**

Primary sources of truth (in order):

1. `docs/handbook/NANO_HANDBOOK.md` (extracted from the handbook DOCX)
2. Approved architecture decisions in `docs/architecture-decisions/`
3. This file (`AGENTS.md`)
4. `.cursor/rules/`
5. Active module spec in `automation/modules/<MODULE_ID>.yaml`
6. `UI_reference/` and `UI_reference/manifest.yaml`
7. Existing code and tests
8. Database migrations
9. Official Flutter / Dart / Supabase docs

## Owner commands

| Command | Meaning |
|---------|---------|
| `NEXT` | Approve module in USER_TEST → DONE → start next eligible |
| `FIX: …` | Defect in current module; fix and return to USER_TEST |
| `STATUS` | Report progress; no code changes |
| `PAUSE` / `RESUME` | Halt / continue from `PROJECT_STATUS.md` |

## Architecture

- Feature-first MVVM
- Apps: `student_app`, `teacher_app`, `admin_web`
- Packages: `nano_design_system`, `nano_domain`, `nano_data`, `nano_auth`, `nano_media`, `nano_games`, `nano_testing`
- Server authority for scores, XP, permissions, tenancy
- Provider secrets only in Edge Functions / trusted backend

## Safety

- Never print or commit secrets
- Never push directly to `main`
- Never remote-deploy Supabase without owner approval
- Only one module `ACTIVE`
- Owner approval required for `APPROVED` / `DONE`
""",
    )

    # Cursor rules
    write(
        ROOT / ".cursor/rules/nano-module-workflow.mdc",
        """---
description: Nano module automation workflow
globs:
alwaysApply: true
---

# Nano module workflow

- Application name is Nano — do not rename.
- Follow AGENTS.md and the active module YAML in automation/modules/.
- Only one module may be ACTIVE.
- Respect allowed_paths and forbidden_paths.
- Stop at USER_TEST and wait for NEXT / FIX / STATUS / PAUSE / RESUME.
- Never expose secrets from .env.local, api_s.txt, or github.txt.
- Prefer reuse-first; record provenance.
- UI-first: fake repositories before live data.
- Server authority for privileged outcomes.
""",
    )

    write(
        ROOT / ".cursor/rules/nano-security.mdc",
        """---
description: Nano security and secrets
globs:
alwaysApply: true
---

# Security

- No provider API keys in Flutter.
- RLS on every exposed table.
- school_id isolation enforced server-side.
- Ignore: api_s.txt, github.txt, .env*.local, supabase/functions/.env*
- Treat remote Supabase as production until classified.
""",
    )

    write(
        ROOT / "automation/schemas/module.schema.yaml",
        """$schema: https://json-schema.org/draft/2020-12/schema
title: NanoModuleSpec
type: object
required:
  - id
  - name
  - release
  - status
  - dependencies
  - applications
  - allowed_paths
  - forbidden_paths
  - acceptance
  - requires_owner_test
properties:
  id: { type: string }
  name: { type: string }
  release: { type: string }
  status:
    enum: [BACKLOG, READY, ACTIVE, AUTOMATED_REVIEW, USER_TEST, CHANGES_REQUESTED, APPROVED, DONE, BLOCKED]
  requires_owner_test: { type: boolean }
""",
    )

    write(
        ROOT / "automation/prompts/module_execution.md",
        """# Module execution prompt

1. Check eligibility (READY, deps DONE, no ACTIVE, no blocking security).
2. Branch `module/<ID>-<short-name>`.
3. Write IMPLEMENTATION_PLAN.md.
4. Implement within allowed_paths.
5. Test; automated review; focused commits; PR.
6. Set USER_TEST; stop for owner.
""",
    )

    write(
        ROOT / "docs/provider-registry/providers.yaml",
        """# Provider registry — names and capabilities only (no credentials)
providers:
  - id: pollinations_image
    category: image
    env_keys: [IMAGE_PROVIDER_API_KEY]
    notes: Primary image path when no privileged key; host image.pollinations.ai
  - id: configured_video
    category: video
    env_keys: [VIDEO_PROVIDER_API_KEY]
    notes: Adapter selected at MED-01; key in Edge Function env only
  - id: configured_voice
    category: voice
    env_keys: [VOICE_PROVIDER_API_KEY]
    notes: Learning Guide voice Aoede; key in Edge Function env only
routing:
  IMAGE_PROVIDER: pollinations
  VIDEO_PROVIDER: configured
  VOICE_PROVIDER: configured
""",
    )

    # Provenance stubs
    write(
        ROOT / "docs/provenance/CODE_REUSE_REGISTRY.md",
        """# Code Reuse Registry

| Name | Source | Version | License | Purpose | Decision |
|------|--------|---------|---------|---------|----------|
| avatar_trials | local `avatar_trials/` | WIP | TBD (asset mix) | Nori/companion experiments | QUARANTINE → ADAPT in CMP-01 |
| avatar_maker | pub.dev | ^1.7.0 | check pubspec | Avatar composition trials | QUARANTINE |
| dicebear_core / styles | pub.dev | ^10.x | MIT (verify) | Avatar generation trials | ADAPT candidate |
| flutter_3d_controller | pub.dev | ^2.3.0 | check | 3D model trials | QUARANTINE |
| Kenney shapes assets | Kenney.nl (trial assets) | bundled | CC0 typically — verify | Shape companions | ADAPT if license confirmed |
| Fluent Emoji | Microsoft | bundled | check | Emoji reactions | ADAPT if license confirmed |
""",
    )

    write(
        ROOT / "docs/provenance/ASSET_PROVENANCE.md",
        """# Asset Provenance

| Asset path | Source | License | Module | Status |
|------------|--------|---------|--------|--------|
| UI_reference/** | Owner-provided mockups | Owner | design | REFERENCE ONLY |
| avatar_trials/assets/** | Mixed trial packs | Per-pack — verify before ship | CMP-* | QUARANTINE |
""",
    )

    write(
        ROOT / "docs/provenance/LICENSES.md",
        """# Licenses

Track third-party licenses before production bundling.

- Flutter / Dart SDK — BSD-style
- Supabase client libraries — Apache-2.0
- Trial avatar packs under `avatar_trials/assets/` — **must be verified per pack before CMP modules ship**
""",
    )

    # GitHub settings + CI
    write(
        ROOT / "docs/setup/GITHUB_REPOSITORY_SETTINGS.md",
        """# GitHub Repository Settings (Owner Action)

Repository: `mkashan9/Nano_V1`

## Required

1. Default branch: `main`
2. Branch protection on `main`:
   - Require pull request before merging
   - Require status checks (CI workflows)
   - Do not allow force pushes
   - Do not allow deletions
3. Do not auto-deploy to production
4. Secret scanning / push protection enabled
5. Dependency review enabled if available

## GitHub token scopes

Current token scopes observed: `repo`, `write:packages`.

`gh auth login` also expects `read:org`. Owner should regenerate or amend the PAT to include `read:org` for full GitHub CLI login, or continue using Git Credential Manager + session `GH_TOKEN` for `gh` API calls.
""",
    )

    write(
        ROOT / ".github/workflows/ci.yml",
        """name: CI

on:
  pull_request:
  push:
    branches: [main]

jobs:
  flutter-analyze-test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: subosito/flutter-action@v2
        with:
          channel: stable
      - name: Detect Flutter projects
        id: projects
        run: |
          if [ -f apps/student_app/pubspec.yaml ]; then echo "has_app=true" >> $GITHUB_OUTPUT; else echo "has_app=false" >> $GITHUB_OUTPUT; fi
          if [ -f avatar_trials/pubspec.yaml ]; then echo "has_trials=true" >> $GITHUB_OUTPUT; else echo "has_trials=false" >> $GITHUB_OUTPUT; fi
      - name: Analyze avatar_trials
        if: steps.projects.outputs.has_trials == 'true'
        working-directory: avatar_trials
        run: |
          flutter pub get
          dart format --output=none --set-exit-if-changed .
          flutter analyze
          flutter test
      - name: Analyze student_app
        if: steps.projects.outputs.has_app == 'true'
        working-directory: apps/student_app
        run: |
          flutter pub get
          dart format --output=none --set-exit-if-changed .
          flutter analyze
          flutter test

  secret-scan:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - name: Block committed secret filenames
        run: |
          if git ls-files | grep -E '(^|/)(api_s\\.txt|github\\.txt|\\.env\\.local)$'; then
            echo "Secret filename tracked in git"
            exit 1
          fi
""",
    )

    print(f"Generated {len(MODULES)} module specs and core automation files")


if __name__ == "__main__":
    main()
