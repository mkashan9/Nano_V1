# SEC-02 Decisions

- Profile IDs are UUIDs reserved for AUTH binding to `auth.users` (no FK yet).
- Client roles cannot insert/update/delete tenancy rows; service role / future admin functions only.
- SECURITY DEFINER helpers live in `nano_internal` so they are not exposed via `/rest/v1/rpc`.
- Independent students have profiles but no `school_memberships`.
- Audit tables wait for SEC-03.
