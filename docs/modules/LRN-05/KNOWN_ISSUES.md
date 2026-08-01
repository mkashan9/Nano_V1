# LRN-05 known issues

- **Strengths are progress, not mastery.** "Going well" reflects how much of a
  subject is finished. Real strengths and improvement areas need quiz scoring
  (QZ-05).
- **No streaks or XP on this screen.** Both belong to the engagement modules
  (GAM-01); the progress screen deliberately stays factual.
- **The profile's `recommendedNext` line is still fixture text.** It comes from
  the STU-05 profile view; the live recommendation is on the progress screen and
  behind Continue Learning. Reconciling the two belongs with the profile pass.
- **`learning_next_up` recomputes on every read.** Fine at pilot size — the
  catalog is small and the view is indexed through `learning_progress` — but a
  materialised path may be needed once content grows.
- **Platform admins see draft content in their own suggestions.** They are not
  learners, so this is cosmetic rather than a leak; learner RLS excludes drafts.
- **The Supabase repository is not yet wired into a live app run.** The app still
  boots with fakes, as with the other learning modules.
