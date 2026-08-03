# VIS-07 manual test

1. Senior → Games (or `--dart-define=NANO_SCREENSHOT_MODE=true --dart-define=NANO_SCREENSHOT_SCREEN=senior_games`).
2. Confirm header, 2×3 game cards with Play, challenges row, Unlock Worlds, achievements/rewards.
3. Review `docs/test-reports/visual/VIS-07/senior_games/`.
4. Run `python automation/scripts/run_visual_test.py --screen senior_games`.
5. Confirm no overflow on small and large phones.
