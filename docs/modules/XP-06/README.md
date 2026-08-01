# XP-06 — Shareable Achievement and Score Cards

## Purpose

Learners can pin up to three achievements on Me and copy privacy-safe share
text for achievements and quiz scores. Cards never include school name, email,
guardian contact, attendance, or marks. Rendered images and social targets
remain SOC-04.

## Delivered

**`featured_achievements`** — own awards only, max three pins, written only
through `set_featured_achievements`.

**`build_share_card`** — first-name-only JSON for `achievement` and
`quiz_score` kinds. Rejects unknown kinds; clients also refuse payloads with
private keys.

**Me** — Featured section, star to pin/unpin, share copies clipboard text.

**Quiz results** — Share score copies a privacy-safe percent card (server path
when the share repository is wired).

## Deferred

Share images, WhatsApp / Communities targets (SOC-04). Admin catalog edits
(ADM-05).
