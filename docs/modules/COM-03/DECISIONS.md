# COM-03 decisions

## Public vs private join

Public communities: `join_community` creates an active `member` row.
Private communities: same RPC creates `pending`; owners/admins accept or reject.

## Invites bypass pending

`redeem_community_invite` always grants active membership (even for private),
subject to ban / expiry / max uses. Invite create is owner/admin only.

## Leave protection

`leave_community` blocks leaving when the caller is the last active owner
(server-side). Pending members may cancel by leaving.

## Open communities

No school gate. All community RPCs still call
`nano_internal.assert_communities_allowed()` (SAFE-04).
