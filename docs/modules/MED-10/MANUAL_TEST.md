# MED-10 manual test

This one is judged by sitting still and watching, not by clicking through. The
failure modes are "looks frozen" and "won't stop fidgeting", and both take a
minute of doing nothing to notice.

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

## 1. Sit on the Junior home for a full minute

Sign in as a Junior learner and then leave it alone.

Nori should look alive and you should stop noticing her. Both halves matter. If
after thirty seconds your eye keeps getting pulled back to the corner, the
amplitude is too high and that is a `FIX`.

Look for a slow breath — she gets very slightly bigger and smaller — and a
gentle drift up and down that is deliberately out of step with it, so the two
never land on an obvious beat.

## 2. Check the frame does not move

While she is breathing, watch the coloured ring around her.

The ring, the little mode emblem, and the play badge must stay perfectly still.
Only Nori inside the circle moves. If the whole badge drifts, a child tapping
it is aiming at a moving target.

## 3. Walk the moods

Start a quiz and go through it slowly.

| Where | Mood | Should read as |
|-------|------|----------------|
| Entering the quiz | point | quicker, leaning in, attentive |
| On a question | thinking | slowest breath, widest side-to-side tilt |
| Finish with a wrong answer | gentleRetry | slow nod, no waggle at all |
| Finish correctly | celebration | fastest and springiest of the set |

**Judge the gentle retry hardest.** It must read as patient. If it looks even
slightly bouncy or pleased, say so — that is the one mood where getting the
motion wrong is actively unkind.

Cover the caption with your hand and check you can still tell celebration from
gentle retry. If you cannot, the signatures are too close together.

## 4. Reduced motion

Open Settings and turn on **Reduce motion**.

Every surface must go completely still, immediately. Not slower — still. Nori
must still be *there*: the drawing stays, only the movement goes. Reduced
motion is a request for calm, not a request for less companion.

Turn it off again and confirm the breath comes back.

## 5. Classroom Mode

Turn Classroom Mode on with Reduce motion off.

Same result: everything still. Thirty screens breathing at once at the front of
a classroom is the thing this prevents.

## 6. Background and return

Switch to another tab or app, wait ten seconds, come back.

Motion should resume smoothly, with no jump, no stutter, and no burst of
catch-up animation.

## 7. Offline

Turn the network off entirely. Everything above must behave identically —
nothing in this tier fetches anything.

## What to say back

- `NEXT` if she looks alive without being distracting
- `FIX: …` naming the mood and whether it is too much or too little
