# MED-01 known issues

- `generate-asset` has never executed. Deployment is owner-gated and local serving
  needs Docker, so the TypeScript path is reviewed but unproven; the Deno adapter
  tests are recorded NOT RUN in TEST_REPORT.
- No voice or video provider is chosen, so those adapters return
  `PROVIDER_UNCONFIGURED`. Expected until MED-03 and MED-04.
- Nothing is published yet: `list_generated_assets` returns nothing because
  approval arrives with MED-05. The client contract and the catalog are therefore
  exercised by tests and fakes rather than by live data.
- No quotas or budgets. The only cost controls today are "superadmin only" and
  "an identical ask is free"; per-day, per-school, and per-feature budgets are
  MED-02.
- Storage cleanup is unhandled. An asset row deleted by hand leaves its file in
  the bucket, and a re-generated file overwrites the old one (`upsert: true`)
  without keeping a version. MED-02 owns retention.
- `CompanionAssetCatalog` is not wired into the student app yet, so
  `clipsAvailable` is still false everywhere. Loading and caching the catalog is
  MED-02.
- The migration ships as two files: the second one corrects the grants and the
  view that the database linter flagged. A fresh apply runs both in order, which
  is correct but means the first file alone is not the final state.
- `record_generated_asset_failure` can fail a row that was never claimed, which
  leaves a `failed` asset with no attempt row. Harmless, but the attempt history is
  then incomplete for that case.
