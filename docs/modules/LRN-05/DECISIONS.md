# LRN-05 decisions

## Views, not RPCs

A recommendation is a read, not a privileged outcome. Two `security_invoker`
views inherit the caller's RLS for free, which is a stronger and shorter security
argument than a `SECURITY DEFINER` function that has to re-derive eligibility.
The module adds no new function, so it adds no new advisor warning.

Rejected: a `recommended_next_topic()` RPC. It would have needed its own copy of
the lock and eligibility logic, and every future change would have had to be made
in two places.

## Built on learning_catalog

Both views select from `public.learning_catalog` rather than joining the base
tables again. That view is the one place where publication state, eligibility, and
prerequisite locks are resolved. Layering on it means a suggestion is, by
construction, a row the learner was already allowed to read.

Cost: `learning_catalog` had to be rebuilt to expose `last_activity_at`. Worth it
— both read models need "what did they touch last", and deriving it twice would
have drifted.

## last_activity_at is greatest(completed_at, last_heartbeat_at, updated_at)

`learning_progress` has an `updated_at` trigger, so any write refreshes it. Using
`greatest` over the three timestamps gives "when did anything happen here" without
adding a fourth column. Note for future tests: `now()` is frozen inside a
transaction, so ordering by recency cannot be exercised by writing rows in
sequence — a timestamp has to be pushed forward explicitly.

## Ranking lives on the server

The client could sort suggestions itself, but then two clients could disagree, and
a stale cache could offer something already finished. The view emits `rank` and
`reason` and the app renders them in order. The reason is shown to the learner so
the suggestion does not look arbitrary.

## Locked topics are counted but never suggested

`topics_locked` is part of the summary so a learner can see why a subject is not
finished, and locked rows are excluded from `learning_next_up`. Hiding locked
content from the count entirely would make the totals lie; suggesting it would
send the learner into a wall.

## Strengths are deliberately coarse

Completion ratio over started subjects is the only honest signal available before
quiz scoring exists. `needsAttention` stays silent unless at least two subjects
are underway and the focus subject is not also the strongest, so the screen does
not praise and scold the same subject.

## Continue Learning resolves through the catalog

The suggestion carries a `topic_version_id`; the player needs a full topic. The
shell loads the catalog and matches on that id, falling back to the progress
screen when there is no match, rather than constructing a partial topic and
risking a wrong lock state in the player.
