# SOC-02 — Friend Requests, Removal, and Blocking

Learners send/accept/decline/cancel friend requests by username or friend
code, remove friends, and block peers. Peer `user_id` values never leave
the server — lists use opaque peer tokens.

## Owns

- `friend_requests`, `friendships`, `blocks`, `friend_peer_tokens`
- Request / friendship / block RPCs
- Friends inbox UI on Profile
- Block-aware limited profile lookup

## Does not own

- Reports / moderation evidence → SAFE-01
- Friends leaderboards → SOC-03
- Social share cards → SOC-04
