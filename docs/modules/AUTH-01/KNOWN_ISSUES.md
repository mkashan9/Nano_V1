# AUTH-01 Known Issues

- Session persistence across full browser reloads needs `supabase_flutter` local storage (pure `supabase` client used for now).
- `login_events` / `device_sessions` writes still service-role only.
- First-login forced password change not implemented.
- Password recovery is AUTH-04.
