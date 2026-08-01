# CMP-03 manual test

Run `student_app` (no network needed):

```powershell
cd d:\nano\apps\student_app
flutter run -d chrome --dart-define=NANO_ENV=development
```

1. **Junior home.** Land on home as a Junior learner. Nori appears above the
   greeting, large, with a caption and a **Guide** badge. Dismiss it with the
   close button: the companion disappears and the page keeps its position — the
   greeting, mission, and subjects do not jump.
2. **No repeat greeting.** Open a subject, then come back to home. Nori does not
   greet again immediately (the cooldown carried across the route), and nothing
   is reserved where it was.
3. **Learning surface.** Open a topic. Nori appears in the player at the same
   Junior size, as **Explorer**. Mark the topic complete and confirm the
   reaction changes to a celebration only after the save succeeds.
4. **Progress empty state.** Open Progress with everything finished. The
   "Everything is finished" panel shows Nori under the line rather than a bare
   panel.
5. **Senior density.** Switch to a Senior learner. Home shows no companion on a
   normal visit — that is intended. Open a topic: Nori is present but noticeably
   smaller than Junior's, beside the content rather than above it.
6. **One at a time.** From a Senior topic, open the quiz. The companion belongs
   to the quiz screen only; nothing shows behind it on the player.
7. **Settings and social carry none.** Open Settings. No companion appears at
   all, at either experience.
8. **Classroom Mode.** Turn on Classroom Mode, then move between home, a topic,
   and Progress. No ordinary guidance appears anywhere, and the layouts are
   identical to the frames where a companion had been dismissed. Finish a quiz
   and confirm the result reaction still shows, silent and static.
9. **Rename.** Rename the companion in onboarding (for example to *Bao*) and
   confirm the caption and badge on home both use the new name.
10. **Coming back.** Leave the app backgrounded for more than 30 minutes (or
    trust step 9 of the automated tests) and return: Nori greets the return
    wherever you are. Backgrounding for a few seconds does not.

Reply `NEXT` to approve, or `FIX: …` if a placement, density, or session rule
looks wrong.
