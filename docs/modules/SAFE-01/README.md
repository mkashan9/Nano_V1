# SAFE-01 — Reporting and Blocking

Learners report peers by username/friend code or opaque peer token, with
optional block. Reports stay open for SAFE-02 moderation; clients never see
peer `user_id` values.

## Owns

- `user_reports` + submit / list RPCs
- Report sheet UI on Profile lookup and Friends
- Evidence snapshot (label/username only) for later queue work

## Does not own

- Moderator queue / sanctions UI → SAFE-02
- Rate limits / restricted links → SAFE-03
- Friend graph CRUD → SOC-02 (reused for blocks)
