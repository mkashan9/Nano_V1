# MED-12 decisions

## Results and onboarding joined the session

CMP-03 kept quiz results on a throwaway runtime so a derived screen could not
spend the session budget. That looked careful and produced the opposite of the
rule that mattered: the one place a learner is celebrated was the one place the
celebration never counted.

MED-12 reverses that. Results and the onboarding welcome use
`CompanionSurfaceStage`. Cooldowns and the budget apply everywhere, which is
the only way "more coverage" does not mean "more interruption" — the same
rules that quieted Senior home also quiet a back-to-back greeting after
onboarding.

## Game stays in the policy and out of the product mount set

The placement policy already says game is visible. Mounting it here would mean
mounting a companion on a screen that does not exist. The coverage helper keeps
two sets: `visibleSurfaces` (what the policy allows) and `productSurfaces`
(what this module promises to mount). Game is in the first and not the second.
Adding it to the second without a screen would fail the build for a reason
nobody can fix in MED-12.

## Curated gaps are celebration clips, not every staticArt slot

The offline pose pack already covers every mood. Reporting every unpublished
`staticArt` slot would be a wall of noise that never clears, because most modes
share one bundled drawing on purpose. The Moderation report lists the slots a
curator can actually close by approving something learners notice missing: the
celebration shortClip for each reachable celebration mode.

## Companion above chrome, never instead of it

Putting the companion inside `NanoEmptyState` / `NanoErrorState` would have
meant every empty/error redesign had to remember not to cover the retry button.
Putting it above those widgets in `NanoViewStateHost` keeps the recovery action
where it was and makes "never blocks recovery" a layout fact rather than a
convention.
