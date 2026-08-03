# VIS-02 manual test

1. Open student app as Junior → Learn tab (or `--dart-define=NANO_SCREENSHOT_MODE=true --dart-define=NANO_SCREENSHOT_SCREEN=junior_learning`).
2. Confirm fox prompt “What shall we learn?”, Numbers carousel + Play, continue “Space Adventure”, bottom nav Learn active.
3. Open `docs/test-reports/visual/VIS-02/junior_learning/` — review reference, actual, overlay, heatmap, scores.
4. Run `python automation/scripts/run_visual_test.py --screen junior_learning`.
5. Confirm no overflow on a small phone and a larger phone.
6. Confirm Gallery / Me QA audit tiles are hidden unless `NANO_DEBUG_TOOLS=true`.
