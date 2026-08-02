# MRK-02 decisions

- Marks editable only while assessment status is `draft`.
- Entry statuses: scored, absent, exempt, not_submitted.
- Scored requires non-negative obtained marks; cannot exceed total unless school `allow_bonus`.
- Save replaces the full entry set for the assessment (server authoritative).
- Students never see drafts (table RPC-only; publish stays MRK-04).
