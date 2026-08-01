# MED-08 — Test report

## Automated

| Suite | Result |
|-------|--------|
| `flutter test packages/nano_domain packages/nano_media packages/nano_design_system packages/nano_data apps/student_app` | PASS — 581 tests |
| `flutter test apps/admin_web` | PASS — 22 tests |
| `flutter analyze` (all packages and apps) | No new issues; 7 pre-existing lints untouched |

### New tests

| File | Covers |
|------|--------|
| `packages/nano_design_system/test/companion_art_test.dart` | The rendering ladder: icon with nothing published, the approved picture when there is one, the icon again when the picture will not load, the clip taking the frame and the badge going with it |
| `packages/nano_design_system/test/nano_media_players_test.dart` | URL minting, static art standing in for a higher tier, a failing resolver throwing at nobody, a stale URL discarded after the reaction moves on, a clip that ends notifying the stage, reduced motion refusing the control, the voice seam notifying |
| `apps/student_app/test/companion_playback_test.dart` | The real app shell: a picture reaching the screen, completeness with nothing published, no control without a player, nothing autoplaying, reduced motion, Classroom Mode |
| `apps/student_app/test/topic_player_page_test.dart` (extended) | A fixture topic never opening a decoder, a real URL being opened, and a video that will not open still crediting watch time |

### Changed tests

`companion_runtime_test.dart` asserted that a published greeting clip must
*not* raise the greeting tier. That is the behaviour this module deliberately
changed, so the assertion was updated and a new test added to pin the half that
still holds: a routine mood never becomes a clip however much is published.

## Live checks

| Check | Result |
|-------|--------|
| Approved assets in `nano_v1` | 3 of 3 present: `guide_greeting_staticArt` (image, 25 KB), `guide_greeting_shortClip` (video, 164 KB), `narration_greeting-2` (voice, 22 KB) |
| Reachability of the Wan clip | Confirmed unreachable before the tier fix; the greeting slot now resolves to `shortClip` when the clip is published |
| Target platforms | android, ios, web — both plugins support all three; no desktop target to strand |

## Not covered by automation

Codec behaviour. A widget test has no decoder, so the `initialize` failure path
is what runs there — which is itself worth testing and is covered. Whether a
real MP4 decodes, plays silently, and returns to the still is the owner manual
test.
