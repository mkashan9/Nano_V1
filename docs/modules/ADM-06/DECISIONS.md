# ADM-06 decisions

## Greenfield catalog

No prior `games` tables. Bootstrap identity + version rows only; learner catalog
and host remain GME-01+.

## Publish mirrors ADM-04

Draft → publish; publishing archives the previous published version for that
game. Disable requires a reason and sets `enabled=false` (published → archived).

## Kill-switch seed for GME-07

`enabled` is the server flag later modules will read. This module does not ship
learner-facing hide/show UX beyond the admin control.
