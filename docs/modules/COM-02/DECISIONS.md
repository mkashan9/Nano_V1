# COM-02 decisions

## Creator is owner

`create_community` inserts the community and an active `owner` membership.

## Role ladder

Roles: owner, admin, moderator, member. Owners can set any role. Admins may
only set moderator/member and cannot touch owners/admins. Last owner cannot be
demoted.

## Text safety

Name/summary/rules pass `assert_text_allowed` (SAFE-03).
