# ATT-01 decisions

- One session per assignment + date + period_key (`daily` when policy is daily).
- Submit is server-authoritative with idempotency key; duplicate submit blocked.
- Statuses: present, absent, late, leave, excused (tap cycles).
- Durable offline queue wiring stays light (page draft until submit); SYNC-01 policy already allows attendance drafts.
- Excel and corrections deferred.
