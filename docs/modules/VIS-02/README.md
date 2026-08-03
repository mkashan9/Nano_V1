# VIS-02 — Junior Learning Stack Visual Replication

## Purpose

Match Junior Learning to `UI_reference/kids/learning_stack.jpeg` (740×1600).

## Deliverables

- Junior Learn tab in nav (Home / Learn / Games / Profile)
- Prompt header, world carousel, continue card
- Screenshot route `/screenshot/junior_learning`
- Generated illustrations + provenance
- Compare evidence under `docs/test-reports/visual/VIS-02/`

## Demo chrome

Scaffolding (persona switchers, gallery, Me QA tiles) stays opt-in via
`debug_tools` / `--dart-define=NANO_DEBUG_TOOLS=true`.

## How to run

```powershell
python automation/scripts/run_visual_test.py --screen junior_learning
```
