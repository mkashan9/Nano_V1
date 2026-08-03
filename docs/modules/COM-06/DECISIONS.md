# COM-06 decisions

## Pins

Owner/admin/moderator may pin/unpin. Pinned strip shows in chat; `is_pinned`
included in message JSON.

## Search

In-community `ILIKE` on message body (min 2 chars). Discover search stays COM-01.

## Gallery

Lists ready attachments for the community (COM-05 rows). Chip list UI only.

## Archive / mute

Per-member prefs. Archived communities are omitted from `my_communities`.
Mute is preference-only (no push plumbing yet).

## Admins-only posting

`posting_mode = admins_only` blocks member sends server-side; mods+ may post.
