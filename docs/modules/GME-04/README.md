# GME-04 — Game Download, Version, and Storage State

Learners see friendly save / update / free-space state for eligible games.
Remote `game_assets` describe versioned packs; local pins track what is on
device. Fixture packs install instantly (no CDN binary yet).

## Owns

- `game_assets` + `list_game_assets_for_learner`
- Local install status resolver (ready / not on device / update available)
- Catalog Save / Update / Free space + storage used copy
- Fake/Supabase asset repositories

## Does not own

- Real CDN download progress UI / resumable transfers
- Trusted score verify → GME-05
- Kill switch → GME-07
- Durable encrypted on-disk packs (in-memory/local pin is enough for fixtures)
