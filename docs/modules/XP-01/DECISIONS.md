# XP-01 decisions

## Awards live inside the source transaction

A separate "award later" job would let a completion succeed and an award fail,
or the reverse. Calling `nano_internal.award_xp` from `complete_topic` and
`submit_quiz_attempt` keeps them atomic. The unique key makes replay free.

## Failed quizzes award nothing

Handbook 11.4: a quiz attempt by itself awards none; score awards on pass.
Retakes after a pass cannot credit again because the source id is the quiz
version, not the attempt.

## Cap refuses quietly

Hitting the daily cap returns null from the award helper without failing the
source action. A learner who finished a video still finished it; they simply
get no XP for that event today. Failing the completion because of a cap would
be the worse outcome.

## Fixture home keeps missions; only XP is live

Rewriting Home as a full live repository is out of scope. The fake accepts an
optional ledger and replaces the XP number. Missions, subjects, and streak
stay fixtures until their modules land.
