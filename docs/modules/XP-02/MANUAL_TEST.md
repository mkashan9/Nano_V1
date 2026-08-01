# XP-02 manual test

## Preconditions

- Development Supabase with XP-01 and XP-02 migrations applied
- Student app signed in as a learner who can complete a topic / quiz
- Optional: SQL access to inspect `xp_progress` and `level_rules`

## Steps

1. Note your current XP on Home (chip) and the level line
   (`Level N · …`). Confirm they match
   `select * from xp_progress where user_id = auth.uid()` (or the balance RPC).

2. Confirm the level matches the seeded curve: level =
   `floor(total_xp / 250) + 1` while the table is still flat.

3. Earn XP that crosses a threshold (e.g. from 240 toward 250+ via a video
   and/or quiz). Re-open Home and Me without restarting the app. Expect the
   level number and "XP to next level" copy to update.

4. Optional SQL: after an award,
   `xp_progress.total_xp` equals `sum(xp_ledger.amount)` and
   `xp_progress.level` equals
   `(nano_internal.level_progress_for_xp(total_xp) ->> 'level')::int`.

## Pass / fail

- Pass: server level fields drive Home/Me; crossing a band updates both.
- Fail: Home still shows a level that disagrees with `xp_progress`, or a
  threshold cross needs an app restart.

## Owner commands

- `NEXT` — thresholds are good; XP-03 can own achievements
- `FIX: …` — describe the mismatch
