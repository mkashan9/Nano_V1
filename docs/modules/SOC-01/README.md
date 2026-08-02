# SOC-01 — Usernames, Friend Codes, and Limited Profiles

Learners claim a unique username and receive a rotatable friend code. Peers
can look up a **limited profile** that never includes user ids, school
records, or contact details.

## Owns

- `social_identities` (username + friend_code)
- `my_social_identity` / `claim_username` / `rotate_friend_code` / `lookup_limited_profile`
- Profile username & friend-code section + limited lookup UI
- Username preference in `league_privacy_label`

## Does not own

- Friend requests / remove / block → SOC-02
- Friends leaderboards → SOC-03
- Share cards → SOC-04 / XP-06
- Reports → SAFE-01
