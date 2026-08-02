# GME-07 — Game Kill Switch and Version Disable

Admin disable (ADM-06) is the kill switch: versions drop from the learner
catalog, new starts fail, and active sessions are aborted so the host can
stop mid-play.

## Owns

- `disable_game_version` aborts active `game_sessions`
- `get_game_session_play_status` learner poll
- Host disabled / kill-switch copy

## Does not own

- Admin disable UI → ADM-06
- Score verify reject path → GME-05
- Leagues → LGE-*
