# XP-05 manual test

## Preconditions

- Development Supabase with XP-01..XP-05 applied
- Student app signed in against that project

## Steps

1. Complete a topic (or pass a quiz). Open Home and Me. Expect the streak
   count to be at least 1 (not stuck on the fixture 7 unless you already had
   more).

2. Complete another activity the same day. Expect the streak count unchanged
   for that second event.

3. Optional: with SQL, set `last_active_on` two days ago and `current_count` to
   5, then open Home. Expect current 0 (or 1 after a new activity) and a gentle
   welcome-back banner — not blame.

## Pass / fail

- Pass: live streak updates once per UTC day; pause messaging is gentle.
- Fail: fixture-only while live, or same-day activity increments twice.

## Owner commands

- `NEXT` — streaks are good; XP-06 can own share cards
- `FIX: …` — describe the mismatch
