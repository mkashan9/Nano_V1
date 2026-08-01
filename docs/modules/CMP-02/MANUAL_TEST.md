# CMP-02 manual test

Run `student_app`.

1. Open the component gallery (developer surface) with the Junior/Senior toggle
   on **Junior**. Scroll the companion row and confirm:
   - each reaction names its mode ("Nori · Guide", "Nori · Explorer",
     "Nori · Quiz coach", "Nori · Builder", "Nori · Celebration");
   - each mode has its own accent and emblem, but the same circle, caption
     bubble, and text sizes;
   - the new-world and level-up moments render as larger framed **story cards**,
     while everything else stays inline.
2. Toggle to **Senior**. Confirm the ordinary navigation moments disappear and
   the result and milestone moments remain, smaller.
3. Finish a quiz (Counting → **Take quiz**). Confirm the results companion is
   labelled **Quiz coach** — a pass is celebrated *as coaching*, not as a
   level-up.
4. Sign in as a first-run learner (or reset onboarding). On the welcome step,
   confirm Nori appears as a framed story card with the **Guide** badge.
5. Rename the companion during onboarding (for example to *Bao*) and confirm the
   badge and caption both use the new name.
6. Turn on **Classroom Mode**, then move around the app. Confirm ordinary
   guidance no longer appears at all, while a quiz result still shows its
   reaction — silent and static.
7. Switch language to Urdu and confirm the mode names are translated
   (کوئز کوچ, کھوجی, جشن).

Nothing here needs network access.

Reply `NEXT` to approve, or `FIX: …` if a mode, frame, or rule looks wrong.
