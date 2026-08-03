# NOT-02 — Quiet Hours, Category Controls, and Digest

## Purpose

Let learners set quiet hours, mute non-mandatory notification categories, and
bundle quiet-hour pushes into a digest. Account/security notices stay unmuted.

## Deliverables

- Domain: `NotificationPreferences`, `NotificationPreferencePolicy`
- Fake preferences repository + push gate (`suppressedMuted` / `heldForDigest`)
- Digest flush into one inbox item
- Me → **Notification preferences** page

## Does not own

- Live preference columns / RLS
- Real OS quiet-hours schedules
- Admin template category taxonomy changes (ADM-07)

## Owner test focus

Me → Notification preferences → enable Quiet hours → mute `learning` →
(from tests/docs) confirm mute suppress + quiet hold + Flush digest.
