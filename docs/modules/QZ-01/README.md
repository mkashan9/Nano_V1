# QZ-01 — Superadmin Question Bank

## Purpose

Give platform admins a place to author and publish quiz questions before those
questions are attached to videos (QZ-02) or scored for learners (QZ-05).

## Deliverables

| Area | What shipped |
|------|--------------|
| Database | `questions`, `question_versions`, `question_bank` view |
| RPCs | `create_question_draft`, `publish_question_version`, `retire_question_version` |
| Domain | `QuestionVersion`, `QuestionOption`, `QuestionPreviewPolicy` |
| Data | `QuestionBankRepository` (fake + Supabase) |
| Admin web | Content → Question bank with Junior/Senior preview |
| Seeds | Counting, addition, and living-things fixture questions |
| Tests | Domain, data, widget, adversarial SQL |

## Rules

- Only platform admins can read or write the bank.
- Learners and school staff see zero rows.
- Drafts are mutable; published and retired versions are immutable.
- Publishing records the actor and timestamp in `audit_events`.
- Retiring keeps the row so future attempts can keep their reference.
- Creating a draft returns any existing versions that share the same normalized
  stem hash (duplicate warning).
- Junior and Senior previews render the same `question_version_id`.

## Out of scope (later modules)

- Attaching questions to a video quiz (QZ-02)
- Student attempt UX (QZ-03 / QZ-04)
- Trusted scoring (QZ-05)
- Bulk CSV import UI (schema accepts provenance notes already)
