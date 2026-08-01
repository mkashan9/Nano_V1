# XP-03 decisions

## Stickers are a kind, not a second ledger

A sticker unlocks the same way a badge does. Splitting tables would duplicate
the unique-grant and evaluate machinery for no product gain. The kind field is
enough for Me to draw a different icon and for XP-06 to treat stickers as
shareable art later.

## Rules read source tables, not the XP ledger alone

First Steps must unlock even when the daily XP cap refuses the video credit.
Quiz Rookie must unlock from `topic_quiz_progress.passed`, not only from a
`quiz_pass` ledger row. Level badges read `xp_progress`.

## Evaluate is idempotent and cheap to call twice

complete_topic and refresh_xp_progress may both evaluate in one transaction.
The unique award key makes that free; missing a call when XP is capped is the
failure that matters.
