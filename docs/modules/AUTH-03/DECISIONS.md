# AUTH-03 Decisions

- One admin_web app serves both school admin and superadmin; principal decides shell/theme.
- `account_kind=school_staff` + membership `school_admin`; `account_kind=platform` + `platform_roles`.
- New school admin UUID `ffffffff-…` (SEC-02 had platform only).
- Debug School/Superadmin switcher disabled when live auth is on.
