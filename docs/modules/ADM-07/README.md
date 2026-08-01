# ADM-07 — Notification Administration

## Purpose

Platform staff can manage notification templates: draft copy, publish for
downstream modules, and disable with an audited reason.

## Delivered

**Table** — `notification_templates` (draft / published / archived + enabled,
mandatory flag, channel policy, deep-link template).

**RPCs** — `list_notification_templates_admin`,
`create_notification_template_draft`, `publish_notification_template`,
`disable_notification_template`.

**Notifications hub** — `/notifications` with list + detail.

## Deferred

Student inbox (STU-06), push delivery / tokens (NOT-01), quiet hours and
category mutes (NOT-02), broadcast fan-out to inbox rows.
