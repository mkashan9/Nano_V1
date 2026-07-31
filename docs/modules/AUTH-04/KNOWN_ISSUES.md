# AUTH-04 Known Issues

- Fixed during USER_TEST: plain `SupabaseClient` defaulted to PKCE and asserted
  `asyncStorage != null` on signup. Apps now build clients via
  `NanoAuthClient.create` with `AuthFlowType.implicit` until `supabase_flutter`
  session persistence lands.
- Running `flutter run` from the repo root builds `nano_workspace`, which has no
  `uses-material-design`, so all icons render as tofu boxes. Always run from
  `apps/<app>`; MANUAL_TEST now says so.
- Leaked password protection (HaveIBeenPwned) is disabled on the Supabase project; owner must enable it in Auth settings.
- The in-app reset link opens the Supabase-hosted recovery page; an in-app "set new password" screen is deferred.
- Email confirmation is currently off for the development project, so signup returns a session immediately. The UI already handles the confirmation-required path.
- No rate limiting beyond Supabase Auth defaults; abuse controls belong to QA-01.
- First-login temporary password change for school users remains open.
