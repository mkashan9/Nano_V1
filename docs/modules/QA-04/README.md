# QA-04 — Accessibility Audit

## Purpose

Encode handbook 8.5 / FND-07 accessibility contract as an executable smoke
checklist: text-scale reflow, semantic labels, captions, non-color status cues,
reduced motion, minimum touch targets, and branding contrast.

## Deliverables

- Domain: `AccessibilityAuditPolicy`, tap / text-scale budgets
- Fake `AccessibilityAuditRepository`
- Me → **Accessibility audit** smoke page (links to Accessibility settings)
- Widget smoke + theme floor alignment test

## Does not own

- Full EN/Urdu bidirectional overflow audit (QA-05)
- Performance / small-device budgets (QA-02)
- Live screen-reader device farms

## Owner test focus

Me → Accessibility audit → All accessibility checks passed; open Accessibility
settings and confirm reduced motion / captions toggles.
