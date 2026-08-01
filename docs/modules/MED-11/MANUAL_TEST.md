# MED-11 manual test

There are sixteen things in the Moderation queue and one of them matters far
more than the rest. Read part 2 before you start clicking.

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

One image, `celebration_celebration_staticArt`. It is the same celebration pose
you already approved in the MED-09 pack, now registered so a clip can be
composed from it.

Approving it unblocks the celebration clip pack. Rejecting it leaves
celebrations as a still picture with local motion, which is what they are now.

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

Voice generation for this whole run cost **7,536 micros**, under one cent. The
Moderation detail pane shows per-asset cost if you want to confirm.

## What to say back

- `NEXT` if the pack is right and you approved the celebration art — the clips
  get rendered next
- `FIX: reject urdu` or similar, naming what to redo
