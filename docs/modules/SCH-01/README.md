# SCH-01 — School Dashboard and Branding

## Purpose

School administrators get a real **Overview** with tenant metrics and setup
progress, plus **Settings** to edit branding (colors, contact, academic year).

## Delivered

**Columns** on `schools` — display name, logo/banner URLs, address, contact,
primary/secondary colors, academic year, setup completed timestamp.

**RPCs** — `school_dashboard`, `update_school_branding` (caller’s school only).

**UI** — `/` Overview and `/settings` branding form for `schoolAdmin`.

## Deferred

Classes (SCH-02), student/teacher management screens, logo file upload to
storage, theme live-apply across the whole shell.
