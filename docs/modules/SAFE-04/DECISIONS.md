# SAFE-04 decisions

## Owner override: open Communities

Communities are independent of schools and teachers — like Discord. Students
create and join freely. School admin has no Communities gate.

(Handbook Phase 9 “behind school flags” does not apply; this owner decision
wins.)

## Junior hard block

Entitlement still requires `student_onboarding.experience_track = 'senior'`.
Missing or junior track never enables Communities.

## Platform emergency switch

`platform_community_policy` defaults **on**. Platform admins may disable
Communities globally in an emergency. There is no per-school policy.

## Client flag is advisory

Nav uses `featureFlags['communities']` from bootstrap. Server helpers remain
authoritative for COM mutations.
