# SCH-04 decisions

- Mirror SCH-03 staff create path (`create_email_auth_user`) with
  `account_kind=school_student`.
- Optional class enrollment on create/import via active SCH-02 classes.
- CSV columns: `display_name,email,class_name` — commit only if preview is clean.
- Suspend clears active enrollment rows.
