# COM-01 decisions

## Open Communities (owner)

Communities are Discord-like and not school-gated. No `school_id` on
`communities`. SAFE-04 still blocks juniors and provides the emergency switch.

## Discovery-only

COM-01 is browse + detail. Create and join CTAs are deferred with explicit copy.

## RPC-only reads

Tables have RLS enabled with no direct policies; clients use security-definer
RPCs that call `assert_communities_allowed`.

## Seed for UX

Migration seeds public communities so Discover is non-empty before COM-02.
