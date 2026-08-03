# NOT-02 — Decisions

1. **Mandatory stay unmuted.** `account` and `security` cannot be muted;
   saves strip illegal mutes.
2. **Quiet + digest.** During quiet hours with digest on, non-mandatory events
   are held and flushed as one inbox digest item.
3. **Quiet without digest.** Non-mandatory events still deliver to inbox
   immediately (in-app), matching “no OS interrupt” intent for later live push.
4. **Fake-first.** Preferences and digest queue are in-memory.
5. **Reuse NOT-01 push repo.** Preference gate lives on
   `FakePushDeliveryRepository.preferences`.
