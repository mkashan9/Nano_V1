# R11 Visual Replication Track — Master Plan

Status: **PLANNED** (do not start VIS-03+ until this plan is owner-approved and VIS-02 is NEXT/DONE)

## Why this plan exists

Functional catalog **R0–R10 is DONE**. Visual work must not invent modules ad-hoc.
Every `UI_reference/` image maps to exactly one VIS module for check-and-balance:
inventory → layout → assets → screenshot/compare → USER_TEST → owner NEXT.

## Scope gate

| In scope | Out of scope |
|----------|--------------|
| Pixel/layout match to reference JPEGs | New product features beyond visual shell |
| Screenshot + compare evidence | Teacher / admin_web visual track (future R12+) |
| Generated illustrations + provenance | Changing handbook functional contracts |
| Junior/Senior student phone shells (740×1600) | Live provider keys in Flutter |

## Shared pipeline (every VIS module)

1. Enrich `UI_reference/manifest.yaml` regions + routes
2. Screenshot route `/screenshot/<screen>` + widget tests
3. Design-system components as needed (reuse first)
4. Assets under `assets/generated/` + provenance YAML
5. `python automation/scripts/run_visual_test.py --screen <id>`
6. Docs under `docs/modules/VIS-XX/` + visual report folder
7. Stop at **USER_TEST** — owner NEXT / FIX / STATUS

Demo chrome stays opt-in (`debug_tools` / `NANO_DEBUG_TOOLS`).

## Module sequence (one ACTIVE / USER_TEST at a time)

| ID | Screen | Reference | Route | Depends on | Status |
|----|--------|-----------|-------|------------|--------|
| VIS-01 | Junior Home | `kids/home.jpeg` | `/screenshot/junior_home` | STU-03, FND-02 | **DONE** |
| VIS-02 | Junior Learning | `kids/learning_stack.jpeg` | `/screenshot/junior_learning` | VIS-01, LRN-01 | **USER_TEST** |
| VIS-03 | Junior Games | `kids/games.jpeg` | `/screenshot/junior_games` | VIS-02, GME-01 | BACKLOG |
| VIS-04 | Junior Profile | `kids/profile.jpeg` | `/screenshot/junior_profile` | VIS-03, STU-05 | BACKLOG |
| VIS-05 | Senior Home | `four_12/home.jpeg` | `/screenshot/senior_home` | VIS-04, STU-04 | BACKLOG |
| VIS-06 | Senior Learning | `four_12/Learning_stack.jpeg` | `/screenshot/senior_learning` | VIS-05, LRN-01 | BACKLOG |
| VIS-07 | Senior Games | `four_12/games.jpeg` | `/screenshot/senior_games` | VIS-06, GME-01 | BACKLOG |
| VIS-08 | Senior Profile | `four_12/profile.jpeg` | `/screenshot/senior_profile` | VIS-07, STU-05 | DONE |
| VIS-09 | Senior Communities | `four_12/Communities.jpeg` | `/screenshot/senior_communities` | VIS-08, COM-01 | ACTIVE |

**Order rationale:** finish Junior shell (matches kids refs) before Senior denser layouts; Communities last (Senior-only).

## Acceptance per module (shared)

- Regions + routes inventoried
- Exact 740×1600 check + one smaller + one larger viewport
- ≤8 visual iterations recorded
- Compare report committed (REVIEW_REQUIRED allowed vs photo refs)
- Provenance for new assets
- No secrets; demo chrome remains opt-in
- Owner manual test packet

## Owner approval needed

Confirm or adjust:

1. Sequence VIS-03 → VIS-09 as above
2. One module at a time (no parallel VIS ACTIVE)
3. Pause new implementation until VIS-02 is approved (NEXT) **or** FIX

Reply **APPROVE VIS PLAN** (optionally with reordering) then continue with VIS-02 NEXT/FIX.
