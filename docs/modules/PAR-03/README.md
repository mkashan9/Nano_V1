# PAR-03 — Guardian Link Foundations

## Purpose

Let a learner create a guardian invite code, demo-accept a link, list active
guardians, and revoke — so guardians can only reach linked children
(handbook verified authorization). Fake-first; no live `guardian_links` table.

## Deliverables

- Domain: `GuardianInvite`, `GuardianLinkRecord`, `GuardianLinkPolicy`
- Fake `GuardianLinkRepository` (create / preview / accept / list / revoke)
- Me → **Guardian links** page
- Active links map to PAR-01 `GuardianChildLink` / `GuardianAccessPolicy`

## Does not own

- Live guardian auth app or push invite delivery (NOT-01)
- Live `guardian_links` RLS migration
- Teacher–guardian feedback (FBK-01)

## Owner test focus

Me → Guardian links → Create invite → Demo accept → see linked guardian →
Revoke → empty list.
