# STU-06 — Student Notifications Inbox

## Purpose

Give learners an in-app inbox they can open from the Home bell: list
notifications, filter All / Unread, and mark items read on open.

## Deliverables

- Domain: `InboxItem`, `InboxFilter`, `InboxMath`
- Data: `StudentNotificationInboxRepository` + fake seed (UI-first)
- `NotificationsInboxPage` with All/Unread segmented filter
- Home junior/senior bell opens the inbox

## Does not own

- Push tokens / OS delivery (NOT-01)
- Quiet hours / preference plumbing (NOT-02)
- Live `inbox_items` schema and fan-out (later NOT/ADM work)

## Owner test focus

From Home, tap the notifications bell → see seeded items → filter Unread →
tap an unread item → confirm it leaves the Unread list and shows a deep-link hint.
