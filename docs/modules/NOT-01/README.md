# NOT-01 — Push Delivery and Deep Links

## Purpose

Register fake device tokens, deliver push events into the STU-06 inbox without
duplicates, keep lock-screen previews free of marks detail, and resolve inbox
deep links with permission-aware fallbacks.

## Deliverables

- Domain: `DeviceToken`, `PushEvent`, `PushDeliveryPolicy`
- Fake `PushDeliveryRepository` (register / invalidate / cleanup / deliver)
- Inbox `deliverFromPush` + `sourceEventId` dedupe
- Inbox **Simulate push** + deep-link resolve via `DeepLinkResolver`
- Aliases: `/learning` → `/`, `/me` → `/profile`

## Does not own

- Quiet hours / category mute / digest (NOT-02)
- Real FCM / APNs SDKs or provider secrets
- Live token tables / Edge fan-out

## Owner test focus

Home bell → Notifications → Simulate push → item appears → tap again →
duplicate ignored. Tap a broken link item → safe fallback message.
