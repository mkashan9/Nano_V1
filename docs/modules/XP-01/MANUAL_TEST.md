# XP-01 manual test

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

Sign in as a Junior learner (`ali@alpha.nano.dev`).

## 1. Starting balance

Open Home and Me. Note the XP chip. Fresh accounts show **0** (ledger empty).
Fixture-only runs without Supabase still show 560.

## 2. Video completion → +10 once

Open a topic, watch past the completion threshold, finish. Home XP should rise
by 10. Complete the same topic again (or re-open and trigger complete): XP must
**not** rise again.

## 3. Quiz pass → +30 once; fail → +0

Pass a quiz you have not passed before: +30. Retake and pass again: no further
credit. Fail a different quiz: XP unchanged.

## 4. Manual adjust (optional)

As `platform@nano.dev`, call `adjust_xp` via SQL or a future admin UI with a
reason. The learner's balance should move and an audit row should exist.

## What to say back

- `NEXT` — ledger is good; XP-02 can own levels
- `FIX: …`
