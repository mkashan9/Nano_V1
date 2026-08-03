# COM-03 implementation plan

1. Migration: `community_invites` + join/leave/request/invite RPCs.
2. Domain: `CommunityInvite` + `canJoin` / `canLeave` / `isPending` / `canInvite`.
3. Data: Fake + Supabase repository methods.
4. UI: Join/Leave, redeem invite, create invite, review pending requests.
5. Tests: domain, fake repo, widget, SQL smoke.
6. Docs + USER_TEST.
