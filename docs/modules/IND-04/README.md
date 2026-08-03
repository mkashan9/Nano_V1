# IND-04 — School Invitation and Account Linking

## Purpose

Let an independent learner redeem a school invite code and become
school-linked without losing learning/game progress.

## Deliverables

- Domain: `SchoolInvitePreview`, `SchoolLinkResult`, `SchoolLinkPolicy`
- Fake `SchoolLinkRepository` (preview + link)
- Me: Link your school — check code → confirm
- Successful link upgrades principal (school role + Flex eligibility)

## Does not own

- School admin invite creation / Excel import (SCH-04)
- Payment / plan changes on link (IND-03 / BIL-01)
- Live membership RPC (deferred)

## Owner test focus

Independent → Me → enter `ALPHA01` → Check code → Link school → shell
becomes school senior with Flex; progress-preserved confirmation shown.
