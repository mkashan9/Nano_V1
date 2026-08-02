# GME-05 decisions

- Reuse GME-02 completion RPC; verification is server-side only.
- Idempotent XP via `award_xp(game_result, session_id)`.
- Reject score/duration/nonce/session mismatches into `rejected_scores`.
- Fake JS scores cannot invent XP without a valid play token + bounds.
- UI never treats unverified results as final XP.
