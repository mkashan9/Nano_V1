# NOT-01 — Decisions

1. **Fake-first push.** No FCM/APNs SDK; tokens and delivery are in-memory.
2. **Dedupe by event id.** Retries of the same `eventId` reuse one inbox row
   (`sourceEventId`).
3. **Reuse DeepLinkResolver.** Inbox opens resolve through FND-04 permission
   gates; unavailable targets fall back to a safe parent.
4. **Lock-screen safety.** Marks/results/payment/account categories (and bodies
   with scores) use a generic preview string.
5. **Path aliases.** `/learning` and `/me` map to current shell routes so older
   templates remain useful.
6. **Quiet hours deferred.** NOT-02 owns mute / digest preferences.
