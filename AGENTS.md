# AGENTS.md — Nano engineering agent contract

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

## Supabase without Docker

- Do **not** use Docker or \supabase start\.
- Use remote-first development against a classified development project (see ADR-0002).
- Migrations live in git; apply via approved remote workflow / MCP.

