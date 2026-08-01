# ADM-02 decisions

## Codes are immutable

Create validates `^[A-Z0-9]{3,16}$`. No regenerate RPC in this module.

## Status always needs a reason

Even restoring to `active` requires a non-empty reason and writes `audit_events`.

## First admin only

`assign_first_school_admin` refuses when an active `school_admin` membership
already exists. Replace-admin is ADM-03.
