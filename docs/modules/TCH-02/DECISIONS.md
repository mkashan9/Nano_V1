# TCH-02 decisions

- Roster is class-scoped; assignment section is display metadata until enrollments use sections.
- Unassigned / ended / foreign assignment ids raise NS074 — no roster leak.
- Roster returns display name only (no email/phone).
- Label-only assignments resolve class via school class name match when `class_id` is null.
