# AUD-01 Test Report

| Check | Result | Notes |
|-------|--------|-------|
| flutter --version | PASS | 3.44.6 |
| dart --version | PASS | 3.12.2 |
| flutter doctor | PASS | No issues |
| git remote configured | PASS | origin → mkashan9/Nano_V1 (no token in URL) |
| git ls-remote origin | PASS | After github.txt removal |
| gh API repo access | PASS | permissions admin |
| gh auth login | FAIL | Token missing `read:org` — workaround documented |
| supabase --version | PASS | 2.109.1 |
| supabase status | FAIL | Docker engine unavailable |
| supabase list_tables nano_v1 | PASS | empty schema |
| Handbook extraction | PASS | docs/handbook/NANO_HANDBOOK.md |
| UI catalog | PASS | 9 images |
| Module YAML count | PASS | 120 |
| Secret files absent from tree | PASS | api_s.txt / github.txt removed |
| git check-ignore secrets | PASS | |
| avatar_trials flutter analyze | FAIL | widget_test references missing `MyApp` |
| avatar_trials flutter test | NOT RUN / expected fail | blocked by analyze issue |
| flutter build web (product) | NOT RUN | no product app yet |

## Verdict

AUD-01 documentation and security baseline are ready for owner review. Known tooling gaps are documented and non-blocking for approving this audit module.
