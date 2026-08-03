# COM-06 — Pinned Messages, Search, Gallery, and Archives

Members can pin messages (mods), search chat text, browse media gallery,
archive/mute communities, and owners can set admins-only posting.

## Owns

- Message pins, search, gallery RPCs
- `community_member_prefs` (mute / archive)
- `communities.posting_mode`
- Chat AppBar search/gallery + pin actions; hub archive/mute/posting controls

## Does not own

- Notification mute plumbing (NOT-*)
- Announcement content type
- Message edit/delete / realtime
