# VIS-09 manual test

1. Senior → Communities (or `--dart-define=NANO_SCREENSHOT_MODE=true --dart-define=NANO_SCREENSHOT_SCREEN=senior_communities`).
2. Confirm header, Weekly Build Challenge, Find a Team, Builder Clubs, Start Your Own Project.
3. Confirm bottom nav Communities is selected (5 tabs).
4. Review `docs/test-reports/visual/VIS-09/senior_communities/`.
5. Run `python automation/scripts/run_visual_test.py --screen senior_communities`.
6. Confirm no overflow on small and large phones.
