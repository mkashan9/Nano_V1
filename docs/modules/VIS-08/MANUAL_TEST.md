# VIS-08 manual test

1. Senior → Profile (or `--dart-define=NANO_SCREENSHOT_MODE=true --dart-define=NANO_SCREENSHOT_SCREEN=senior_profile`).
2. Confirm greeting, Master Builder / Level 28, streak, 2×2 metrics, This Week, Achievements, Top Builders, Learning Journey.
3. Confirm bottom nav Profile is selected (5 tabs including Communities).
4. Review `docs/test-reports/visual/VIS-08/senior_profile/`.
5. Run `python automation/scripts/run_visual_test.py --screen senior_profile`.
6. Confirm no overflow on small and large phones.
