# GME-02 — Secure Web Game Container

Learners start an eligible **web** game in a restricted host with a
short-lived play token and a narrow typed bridge. Fixture games run
in-app; remote HTTPS WebView registration is deferred. Score verify /
XP stay with GME-05.

## Owns

- `game_sessions` + `start_game_session` / `abort_game_session` /
  `report_game_client_completed`
- Origin allowlist + bridge message validation
- `GameSessionRepository`, `GameBridgeController`, fixture surface
- Catalog **Play** → host page

## Does not own

- Trusted score verify / XP → GME-05
- Flutter-native games → GME-03
- Asset download/cache → GME-04
- Kill switch UX → GME-07
