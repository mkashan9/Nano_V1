# SCH-03 decisions

- Teacher create uses SECURITY DEFINER insert into `auth.users` + profile +
  membership (no service-role key in Flutter).
- CSV-first import; commit only when preview has zero failures.
- Suspend updates membership and teacher profile status with audited reason.
- Students stay SCH-04.
