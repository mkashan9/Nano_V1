# MED-11 manual test

The sixteen narration and art assets were **already approved** on your
instruction on 2026-08-02, without the Urdu being listened to. Parts 1–3 below
are therefore a check after the fact rather than a gate: if something is wrong,
it can still be rejected and the companion falls back a rung.

What is still genuinely undecided is the **five celebration clips** in part 3b.

Everything is downloaded locally so you can play it without launching anything:

- `review/MED-11-audio/` — fifteen recordings, with `WHAT_YOU_SHOULD_HEAR.md`
- `review/MED-11-clips/` — five clips, with `WHAT_YOU_SHOULD_SEE.md`

For the queue itself:

```powershell
cd d:\nano\apps\admin_web
flutter run -d chrome --dart-define=NANO_ENV=development
```

Sign in as `platform@nano.dev` / `NanoPlatformDev1!` and open **Moderation**.

## 1. The English recordings — seven of them

`narration_idle-1`, `point-1`, `point-2`, `thinking-1`, `retry-1`,
`celebration-1`, `celebration-2`, all `locale = en`.

Play each one and check three things:

- It is the same voice as the greeting you approved in MED-06. A companion that
  changes voice mid-session is worse than one that never speaks.
- It reads the caption shown, word for word. A recording of *different* words
  is never offered to a learner, but it should not be approved either.
- `retry-1` in particular: *"Some of these need another look. We can try
  again."* It has to sound patient. If it sounds disappointed, reject it — that
  line plays to a child who just got something wrong.

## 2. The Urdu recordings — the real decision

Same seven slugs plus `greeting-2`, all `locale = ur`. Eight files.

**The cast voice was chosen against English lines.** It is a Fish Audio
reference clone, and nothing about it was selected or verified for Urdu. Every
one of these rendered without error at a plausible size and cost — that is all
a machine can tell you.

Listen for whether it reads Urdu **as Urdu**, or as an English speaker sounding
out an unfamiliar script. Pronunciation, rhythm, and where the stress falls.

If it is wrong, **reject all eight**. That is a normal outcome, not a failure of
the module:

- Strict locale match means a rejected Urdu recording shows the caption instead
- Urdu learners are then exactly where they are today, having lost nothing
- We would go and cast an Urdu voice properly, which is its own decision

Approving a bad Urdu voice is the only genuinely bad outcome here, and it is
the easy one to reach by clicking through.

## 3. The celebration picture

Five image rows, all byte-identical: the celebration pose from the MED-09 pack,
registered once per celebration mode because clip composition resolves art by
slot. Approved already; the clips below were composed from it.

## 3b. The five celebration clips — the open decision

In `review/MED-11-clips/`, or in Moderation as video. All silent by design, so
they never fight the narration. All composed from that one drawing, all Wan
renders, all free.

Watch for two things. **Is it still Nori** — composition can distort a face
across four seconds even when the source is fixed. And **is it calm enough to
meet several times a day** — every direction caps at three or four seconds and
says "calm and unhurried", and anything that reads as frantic is a reject.

Watch `guide_celebration` twice. Guide is the default mode, so it is the
celebration most learners actually reach, and it is the one whose first render
came back from the json2video fallback — the provider you rejected twice in
MED-06 for looking fake. That render was rejected and this is a fresh Wan one.

## 4. Hear it in the app

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

Sign in as a Junior learner and walk a quiz. Wherever Nori appears there should
now be a **Listen** button, and it should read the caption on screen.

Switch the app to Urdu and repeat. If you rejected the Urdu set, the Listen
button must **disappear** rather than play English — that is the strict locale
rule, and it is worth seeing work.

## 5. The spend

Voice generation cost **7,536 micros** and all five clips cost **nothing**, so
the whole module is under one cent. The one exception was the json2video render
of `guide_celebration` at 15,000 micros, which was rejected.

## What to say back

- `NEXT` — the clips are good and MED-12 starts
- `FIX: …` naming the clips or recordings to redo
