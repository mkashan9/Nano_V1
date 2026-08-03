# CMP-04 Test Report

## Automated

| Suite | Result | Notes |
|-------|--------|--------|
| `packages/nano_domain/test/companion_runtime_test.dart` | PASS | |
| `packages/nano_domain/test/companion_modes_test.dart` | PASS | |
| `packages/nano_domain/test/companion_identity_test.dart` | PASS | |
| `packages/nano_design_system/test/nori_pose_pack_test.dart` | PASS | Run from package dir for assets |
| `packages/nano_design_system/test/companion_art_test.dart` | PASS | |
| `packages/nano_design_system/test/companion_stage_test.dart` | PASS | |
| `flutter analyze` | pending in final pass | |
| `flutter build web` | pending in final pass | |
| Deno Edge voice tests | NOT RUN | No Deno on agent host; gemini_voice_test updated to Puck |
| Wan video jobs | NOT RUN | VIDEO_REVIEW_REQUIRED; budget reserved |

## Manual / visual

- Contact sheet: `docs/test-reports/companion/CMP-04/static_pose_contact_sheet.png`
- Character sheet: `assets/companion/master/avatar_character_sheet.png`
- Dev gallery: `/dev/companion-cmp04`

## Gaps accepted for USER_TEST

- Owner male voice MP3 not on disk → captions + voice id config only
- Tier-2 clips not generated → static fallbacks
