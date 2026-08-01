# MED-03 test report

Date: 2026-08-01

## Database (development project `nano_v1`)

| Check | How | Result |
|-------|-----|--------|
| MCP migrations `med03_voice_narration_voices`, `_lines`, `_rpcs` | Supabase MCP | applied |
| Two voices are two recordings; aspect ignored for voice; language splits | `execute_sql` | all true |
| First request uses published wording, charges once; reuse free; Urdu separate | `execute_sql` | ok |
| Placeholder greeting refused (`NM007`); no row, no charge | `execute_sql` | ok |
| Unknown line (`NM004`), unknown voice (`NM002`), voice on image (`NM002`) | `execute_sql` | ok |
| Disabled voice refused; captions still list 9 lines | `execute_sql` | ok |
| Learner cannot author/request; tables invisible; reads 9 captions, 0 audio | `execute_sql` | ok |
| Published wording immutable (`NM008`) | `execute_sql` | ok |
| One published version per line (`23505`) | `execute_sql` | ok |
| New wording retires old; old approved audio not offered | `execute_sql` | ok |
| English-only line: Urdu request refused; Urdu reader does not see the line | `execute_sql` | ok |
| Nothing left behind | `execute_sql` | 0 assets, 9 lines, 9 published, 1 voice, 0 voice usage |
| Security advisors | MCP `get_advisors` | no new ERROR; new WARNs are the intended signed-in narration RPCs (gated internally), same class as MED-02 |

The full script is `supabase/tests/med03_voice_narration.sql`, run in blocks through
MCP `execute_sql`, each block inside a transaction that rolled back.

## Dart

| Suite | Command | Result |
|-------|---------|--------|
| Domain narration | `dart test packages/nano_domain/test/narration_line_test.dart` | 5 passed |
| nano_media | `dart test packages/nano_media` | 37 passed |
| Data narration | `dart test packages/nano_data/test/narration_repository_test.dart` | 8 passed |
| Design system narration | `flutter test packages/nano_design_system/test/companion_narration_test.dart` | 9 passed |
| Student app | `flutter test apps/student_app` | 116 passed |
| Static analysis | `dart analyze` | pre-existing infos/warnings only; fixed a corrupted root `analysis_options.yaml` that blocked analysis |

### Coverage worth naming

- **Personalised lines never play.** Catalog checks the raw template, not the
  substituted caption — substitution would have hidden `{name}` and wrongly
  allowed playback.
- **Sound defaults to the reaction.** `choose` uses `reaction.speaks` when the
  caller does not override, so a muted reaction cannot be spoken by accident.
- **Language switch clears signed URLs.** English audio credentials do not
  survive into an Urdu session.
- **Listen control is absent without a player, recording, or permission.** Nine
  widget cases cover muted, Classroom Mode, wording mismatch, late catalog
  attach, failed URL mint, and silence on dismiss.

## Not run

| Test | Why |
|------|-----|
| `gemini_voice_test.ts` | No Deno on this machine |
| Live `generate-asset` voice call | Undeployed; no `VOICE_PROVIDER_API_KEY` (owner approval) |
| Real device playback | No audio plugin attached yet |
