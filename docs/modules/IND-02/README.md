# IND-02 — Independent Access Rules and Entitlements

## Purpose

Define what an independent learner may use (learning, games, communities)
without payment plumbing. Full / limited / restricted tiers drive Home
warnings, Me access status, and a games gate when reduced.

## Deliverables

- Domain: `IndependentEntitlements`, `IndependentAccessPolicy`
- Fake `IndependentAccessRepository`
- Home calm banners for limited / restricted
- Profile Access card for independents
- Games tab blocked when games are not entitled

## Does not own

- Trial / free / paid purchase flows (IND-03)
- Billing, receipts, plans (BIL-01)
- School invitation linking (IND-04)

## Owner test focus

Independent role → Me shows Access → inject restricted seed (or use
debug/test) → Games shows blocked message while Home learning still works.
