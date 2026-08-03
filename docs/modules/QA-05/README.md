# QA-05 — Urdu and Bidirectional Layout Audit

## Purpose

Encode FND-06 English/Urdu readiness as an executable smoke checklist: RTL for
Urdu, LTR for English, core copy strings, small-phone overflow, and text-scale
1.3 on a 360px floor.

## Deliverables

- Domain: `BidiLayoutAuditPolicy`, small-phone / text-scale budgets
- Fake `BidiLayoutAuditRepository`
- Me → **Urdu & bidirectional** smoke page (links to Locale preview)
- Widget smoke asserting RTL Directionality for Urdu

## Does not own

- Full ARB / Crowdin pipeline
- Accessibility contract gates (QA-04)
- Pilot release packaging (QA-06)

## Owner test focus

Me → Urdu & bidirectional → All bidi checks passed under Urdu RTL; toggle
English and confirm LTR; open Locale preview.
