# XP-04 manual test

## Preconditions

- Development Supabase with XP-01..XP-04 applied
- Student app signed in against that project

## Steps

1. Open **Home**. Expect daily/weekly mission titles from the seed (Complete a
   lesson, Pass a quiz, Finish 3 lessons, Pass 2 quizzes) rather than only the
   old fixture trio — seniors see all four; juniors see three.

2. Complete a topic video. Re-open Home. Expect the daily lesson mission to
   show progress or **Done**, and XP to rise by the video award plus 15 if that
   completed the mission for the first time today.

3. Pass a quiz. Expect the daily quiz mission to complete once (+20 bonus once).

4. Replay the same completion / quiz. Expect no second mission bonus row
   (`source_kind = mission_complete` unique per mission:period).

## Pass / fail

- Pass: Home plan is live; missions complete once; bonus XP is idempotent.
- Fail: fixtures only while live, or a replay pays the bonus twice.

## Owner commands

- `NEXT` — missions are good; XP-05 can own streaks
- `FIX: …` — describe the mismatch
