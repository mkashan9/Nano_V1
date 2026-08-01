# MED-04 test report

Date: 2026-08-01

## Database (development project `nano_v1`)

| Check | Result |
|-------|--------|
| MCP migrations for long jobs, library, RPCs, seed | applied |
| Clip request uses published direction; reuse free; shape splits | ok |
| Unauthored shape / unknown reaction / bad slug refused | ok |
| Learner cannot author/request; tables invisible; 0 approved clips | ok |
| Published direction immutable; one published version | ok |
| Abandoned job recovered without double charge | ok |
| Live job left alone; exhausted job failed and recharged | ok |
| Progress renews claim; completion clears schedule | ok |
| Nothing left behind | 0 assets, 3 clips, 3 published, 0 video usage |
| Security advisors | no new ERROR; new WARNs are intended clip RPCs |

Script: `supabase/tests/med04_video_reaction_library.sql`.

## Dart / Flutter

| Suite | Result |
|-------|--------|
| Domain + media + reaction clip repository | 275 passed |
| Design system companion clip widgets | 6 passed |
| Student app asset availability | 3 passed |

## Not run

| Test | Why |
|------|-----|
| `gemini_veo_test.ts` | No Deno |
| Live Veo call | Undeployed; no key |
| Real video playback | No plugin attached |
