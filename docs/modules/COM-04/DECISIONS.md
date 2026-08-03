# COM-04 decisions

## Active members only

List/send/react require `caller_community_role` (active membership) plus
`assert_communities_allowed`.

## SAFE-03 gate on send

`send_community_message` calls `assert_community_message_allowed` (rate limit
`community_message` + `assert_text_allowed`).

## Mentions

Mentions are explicit UUID lists; only active members of the same community
are stored. UI picks a member via `@` rather than free-text parsing.

## Reactions

Toggle per (message, user, emoji). Aggregated counts returned with messages.
