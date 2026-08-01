# MED-09 manual test

The point of this test is not "does it render" — the automated tests cover
that. It is **is this the Nori you want locked**, because every pose generated
from here is judged against the sheet you approve now.

## 1. Review the character sheet

Open `docs/companion/NORI_CHARACTER_SHEET.md`.

Read the **Rejection triggers** section in particular. That list is what a
reviewer will use to turn down future art, so anything missing from it is
something that will get approved by accident later.

The same content is in the database, which is what admin_web will read:

```sql
select * from public.current_character_sheet();
```

Say so if you want anything changed. Locking a sheet you half-agree with is
worse than not having one.

## 2. Look at the six poses together

They are in `packages/nano_design_system/assets/companion/`. Open the folder and
view them as one set, not one at a time — drift only shows in comparison.

| File | Should read as |
|------|----------------|
| `nori_greeting.jpg` | waving hello (this is the art you already approved) |
| `nori_idle.jpg` | calm, resting, doing nothing |
| `nori_point.jpg` | showing you where to go |
| `nori_thinking.jpg` | working something out, not worried |
| `nori_gentle_retry.jpg` | kind, offering another try — **not sad, not disappointed** |
| `nori_celebration.jpg` | delighted, arms up |

Check them against the sheet: same silhouette, ear nubs present and in the same
place, belly patch present, same purple, same eyes, blush on every one.

## 3. See them in the app

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

Sign in as a Junior learner.

- **Home** — Nori is the approved published greeting art, exactly as in MED-08.
  Published still wins over bundled; that is the point of this step.
- **Start a quiz** — Nori appears as the pointing pose, in the Quiz Coach ring.
- **Answer a question** — the thinking pose.
- **Finish with a wrong answer** — the gentle retry pose. This is the one to
  judge hardest: it must read as encouragement, never as disappointment.
- **Finish correctly** — the celebration pose.

Nowhere should you see the old paw, hand, or star icon.

## 4. Airplane mode

Turn off the network entirely and reopen the app.

Nori must still be there in every one of those places. The published home art
will fail to fetch and fall to the bundled greeting pose — same character, same
mood, so the fall should be almost invisible. That is the offline floor working.

## 5. Junior and Senior

Sign in on a Senior account and walk the same quiz. Senior shows the companion
smaller and less often, but every pose it does reach must be a drawing.

## What to say back

- `NEXT` if the sheet and the pack are right
- `FIX: …` naming the pose and what is wrong with it — a rejected pose gets
  regenerated against the same sheet, which is exactly the loop this module
  builds
