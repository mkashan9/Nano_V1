# QZ-03 — Junior Quiz Experience

## Purpose

Give Junior learners a companion-led, one-question-per-screen quiz after a
topic. Selections stay local; trusted scoring lands in QZ-05.

## Deliverables

| Area | What shipped |
|------|--------------|
| Domain | `JuniorQuizFlow` (one screen, moods, no client score) |
| Data | `LearnerQuizRepository` (fake + Supabase `learner_quiz`) |
| Student app | `JuniorQuizPage` + Take quiz on Junior topic detail/player |
| Tests | Domain, data, widget |
| Docs | Module pack + manual test |

## Rules

- One question per screen.
- Options never carry `is_correct`.
- Companion prompts are gentle; finish notice says score is saved later.
- Senior shells do not open this Junior surface.
- No attempt tables or scoring RPCs in this module.

## Out of scope

- Senior quiz UX (QZ-04)
- Trusted attempts / scoring (QZ-05)
- Results and explanations (QZ-06)
