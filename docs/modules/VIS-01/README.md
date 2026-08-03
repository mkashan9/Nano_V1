# VIS-01 — Junior Home Visual Replication

## Purpose

Match Junior Home to `UI_reference/kids/home.jpeg` (740×1600) with screenshot
infrastructure, generated illustrations, and honest visual evidence.

## Deliverables

- Enriched UI_reference manifest + catalog regions
- Screenshot route `/screenshot/junior_home` + `NANO_SCREENSHOT_MODE`
- Design-system Junior header / continue hero / subject world cards
- Generated assets under `assets/generated/` + provenance
- Compare scripts + visual report folder

## Intentional deviations

- Missions / CompanionSurfaceStage off by default (enable via flags)
- Flutter `matchesGoldenFile` hung on this Windows host — reports use a layout
  stand-in raster for compare; interactive UI proven by widget tests
- English / Stories assets marked `ASSET_REVIEW_REQUIRED` (possible residual text)

## Owner test focus

Review `docs/test-reports/visual/VIS-01/junior_home/` vs reference; run
`python automation/scripts/run_visual_test.py`.
