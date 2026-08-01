# QZ-04 — Senior Quiz Experience

## Purpose

Give Senior learners a navigable quiz with review before finish. Selections
stay local; trusted scoring lands in QZ-05.

## Deliverables

| Area | What shipped |
|------|--------------|
| Domain | `SeniorQuizFlow` (jump, previous/next, review, finish gate) |
| Student app | `SeniorQuizPage` + Take quiz on Senior topic detail/player |
| Tests | Domain + widget |
| Docs | Module pack + manual test |

## Rules

- Question navigator chips jump without clearing answers.
- Review lists answered vs unanswered; Finish stays disabled until all answered.
- Options never carry `is_correct`.
- Finish notice says score is saved later (no client percent).
- Junior continues to use `JuniorQuizPage`.

## Out of scope

- Trusted attempts / scoring (QZ-05)
- Results and explanations (QZ-06)
