# QA-03 — Offline and Poor-Network Testing

## Purpose

Encode SYNC-01 / ADR-0007 offline rules as an executable smoke checklist:
trusted mutations stay blocked offline, drafts and cache remain available,
conflicts surface, and poor-latency (≥2s) keeps retry chrome.

## Deliverables

- Domain: `OfflineNetworkAuditPolicy`, `NetworkQualityPolicy`, poor-network budgets
- Fake `OfflineNetworkAuditRepository`
- Me → **Offline & poor network** smoke page (links to Sync Preview)
- Widget smoke for offline / poor / profile open

## Does not own

- Live network probing or device farms
- Performance / small-device budgets (QA-02)
- Accessibility audit (QA-04)

## Owner test focus

Me → Offline & poor network → All offline checks passed; toggle Poor and
confirm banner / retry guidance still pass.
