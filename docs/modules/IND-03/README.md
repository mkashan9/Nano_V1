# IND-03 — Trial, Free, and Paid States

## Purpose

Surface free / trial / paid / grace / expired plan states for independents
and map them onto IND-02 entitlements. No payment capture — that is BIL-01.

## Deliverables

- `IndependentPlanKind` + `IndependentPlanSnapshot` + `IndependentPlanMath`
- Fake plan transitions (`applyPlan`) on the access repository
- Me Access card shows plan kind, days left, calm Start free trial
- Expired maps to reduced access (learning open, games paused)

## Does not own

- Payment receipts / store billing (BIL-01)
- School invitation linking (IND-04)
- Manipulative purchase CTAs on children’s Home

## Owner test focus

Independent Me with free plan → **Start free trial** → Trial with days left.
Expired seed → reduced Access copy, games blocked, learning open.
