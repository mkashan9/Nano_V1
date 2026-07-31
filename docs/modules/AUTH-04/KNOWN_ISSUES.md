# AUTH-04 Known Issues

- Leaked password protection (HaveIBeenPwned) is disabled on the Supabase project; owner must enable it in Auth settings.
- The in-app reset link opens the Supabase-hosted recovery page; an in-app "set new password" screen is deferred.
- Email confirmation is currently off for the development project, so signup returns a session immediately. The UI already handles the confirmation-required path.
- No rate limiting beyond Supabase Auth defaults; abuse controls belong to QA-01.
- First-login temporary password change for school users remains open.
