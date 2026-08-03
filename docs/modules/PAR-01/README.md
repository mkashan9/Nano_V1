# PAR-01 — Weekly Parent Guidance Card

## Purpose

Show a child-safe weekly parent tip on Me, and enforce that guardians can
only load guidance for linked children. PDF upload is PAR-02.

## Deliverables

- Domain: `ParentGuidanceCard`, `GuardianChildLink`, access + safety policy
- Fake `ParentGuidanceRepository`
- `ParentGuidancePage` + Me entry “For parents this week”
- Privacy hint: marks and private notes never shown

## Does not own

- Superadmin weekly PDF upload (PAR-02)
- Full guardian auth / linking UI (PAR-03)
- Teacher–guardian feedback threads (FBK-01)

## Owner test focus

Open Me → For parents this week → see tip + home activities + privacy hint.
Confirm unlinked guardian load is rejected in tests/docs.
