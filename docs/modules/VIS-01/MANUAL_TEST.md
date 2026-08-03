# VIS-01 manual test

1. Open student app with `--dart-define=NANO_SCREENSHOT_MODE=true` (lands on `/screenshot/junior_home`) **or** navigate Junior home in normal shell.
2. Confirm header avatar ring, “Hi Ali”, star badge **7**, Continue Learning hero with **Start**, 2×2 subjects, bottom nav Home/Learn/Games/Profile.
3. Open `docs/test-reports/visual/VIS-01/junior_home/` — review reference, actual, overlay, heatmap, scores.
4. Run `python automation/scripts/run_visual_test.py`.
5. Confirm no overflow on a small phone and a larger phone.
