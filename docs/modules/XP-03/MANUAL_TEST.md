# XP-03 manual test

## Preconditions

- Development Supabase with XP-01..XP-03 migrations applied
- Student app signed in against that project
- A learner who can complete a topic and pass a quiz

## Steps

1. Open **Me**. If you already have completions or level ≥ 2 from earlier
   modules, expect the matching awards (First Steps, Quiz Rookie, Rising Star,
   Level Climber) rather than only the old fixtures.

2. Complete a first topic video (or any topic if First Steps is not yet
   granted). Re-open Me. Expect **First Steps** with the sticker icon.

3. Pass a quiz. Expect **Quiz Rookie** once. Submit again / retake: still one
   Quiz Rookie row.

4. Earn enough XP to reach level 2 (and 3 if convenient). Expect **Rising
   Star** / **Level Climber** without restarting the app.

5. Optional SQL: `select slug from achievement_awards a join
   achievement_definitions d on d.id = a.achievement_id where user_id =
   auth.uid()` — no duplicate slugs.

## Pass / fail

- Pass: awards appear from trusted events, stickers look distinct, no
  duplicates on replay.
- Fail: Me still shows only fixtures while live, or a replay creates a second
  row for the same slug.

## Owner commands

- `NEXT` — achievements are good; XP-04 can own missions
- `FIX: …` — describe the mismatch
