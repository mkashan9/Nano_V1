# VIS-05 manual test

1. Senior/independent → Home (or `--dart-define=NANO_SCREENSHOT_MODE=true --dart-define=NANO_SCREENSHOT_SCREEN=senior_home`).
2. Confirm header (my future / streak / Gold Builder), Continue Building hero, Today's Mission, Builder Dashboard, Continue Learning rows, Build Challenge.
3. Confirm bottom nav includes Home + Learn (and Flex when school-eligible).
4. Review `docs/test-reports/visual/VIS-05/senior_home/`.
5. Run `python automation/scripts/run_visual_test.py --screen senior_home`.
6. Confirm no overflow on small and large phones.
