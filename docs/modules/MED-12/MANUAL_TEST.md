# MED-12 manual test

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

Sign in as a Junior learner (e.g. `ali@alpha.nano.dev`).

## Walk the surfaces

| Screen | Expect |
|--------|--------|
| Onboarding welcome (fresh account or reset) | Nori greeting, story-card framing |
| Junior home | Nori greeting, hero size |
| Topic player | Nori on video start |
| Progress with nothing left to recommend | Nori on empty state |
| Quiz questions | Nori thinking / coaching, inline |
| Quiz results (pass) | Celebration, same session companion |
| Quiz results (fail) | Gentle retry |

Senior: home stays quiet on a normal visit; companion is aside-sized when it
does appear. Social / profile / accessibility: no companion.

## Recovery is never covered

Force an error (airplane mode mid-load on a quiz, or kill the network and open
a page that needs it). Nori may appear above the error chrome. **Try again**
must still be tappable. Tap it.

## Moderation gaps

```powershell
cd d:\nano\apps\admin_web
flutter run -d chrome --dart-define=NANO_ENV=development
```

Sign in as `platform@nano.dev` / `NanoPlatformDev1!`. Open **Moderation**.

Above the queue you should see either "Every celebration clip is approved" or
a short list of missing `*_celebration_shortClip` slots. After MED-11 that list
should be empty on development.

## What to say back

- `NEXT` — MED-12 done, avatar arc closed
- `FIX: …` — naming the surface or behaviour
