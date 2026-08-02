# CLS-03 — Scheduling, Expiry, and Acknowledgement

Teachers schedule draft announcements, set expiry, and see acknowledgement
counts. Students acknowledge via server RPC (student UI → FLX-04).

## Owns

- `scheduled_publish_at` / `expires_at` / `requires_acknowledgement`
- `classroom_acknowledgements`
- `student_classroom_acknowledge`
- Lazy promote of due scheduled drafts on list
- Teacher UI schedule/expiry/ack summary

## Does not own

- Student classroom feed → FLX-04
- Archives / folders
