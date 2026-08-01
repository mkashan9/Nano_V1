# MED-08 — Manual test

All three assets this module needs are already approved in `nano_v1`:

| Slot | Kind | Size |
|------|------|------|
| `guide_greeting_staticArt` | image | 25 KB |
| `guide_greeting_shortClip` | video (Wan) | 164 KB |
| `narration_greeting-2` | voice (guide_educational) | 22 KB |

All three belong to the Guide greeting, which is the reaction the Junior home
shows on arrival — so one screen demonstrates the whole module.

## Run it

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome `
  --dart-define=NANO_ENV=development `
  --dart-define=SUPABASE_URL=<development url> `
  --dart-define=SUPABASE_ANON_KEY=<development anon key>
```

Sign in as a junior learner.

## What to check

1. **Nori is a picture.** On the Junior home, the companion is the approved
   artwork inside the mode ring, not the paw icon. This is the single thing the
   whole media arc has been building toward.
2. **Listen works.** Tap the speaker button beside the caption. The guide voice
   reads *"Good to see you again."* — the exact words on screen, in the voice
   cast in MED-06.
3. **Play works.** Tap the picture (it carries a play badge). The Wan clip plays
   silently, Nori waves, and the still comes back on its own when it ends.
4. **The clip is silent.** Start the clip while the voice is playing. The voice
   is not interrupted or talked over.
5. **Sound off.** Settings → turn sound off. The Listen button disappears; the
   caption stays and reads the same words.
6. **Reduced motion.** Turn it on. The play badge disappears and the picture
   stays. Motion is declined; the artwork is not motion.
7. **Classroom Mode.** Turn it on. Sound and haptics lock off, and nothing can
   be played aloud.
8. **Nothing autoplays.** Reload the app several times. No voice and no clip
   ever starts without your tap.
9. **Offline.** Kill the network and reload. Nori falls back to the mood icon
   and the caption; nothing is blank, and nothing throws.
10. **Watch credit is unchanged.** Open a topic, press play, let it run, pause.
    Progress and credited time behave exactly as they did before this module —
    fixture topics still run on the deterministic clock.

## What you will not see, and why

- Any reaction other than the greeting is still an icon. One picture is
  approved; MED-09 produces the rest.
- Nori does not breathe or blink yet. That tier is MED-10.
- Urdu narration is silent with a caption, which is the strict-locale rule
  working, not a bug.
