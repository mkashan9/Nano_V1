# ANA-01 — Product Analytics and School Health

## Purpose

Document the privacy-safe analytics event taxonomy and show school health
scores that compose from operational rates (attendance, assessment publication,
learning participation) with coverage/incident penalties.

## Deliverables

- Domain: `AnalyticsEventTaxonomy`, `SchoolHealthMath`, `SchoolHealthSnapshot`
- Fake `AnalyticsHealthRepository`
- Platform Analytics: school health list + event taxonomy
- School Reports: school health score card

## Does not own

- Live `analytics_events` warehouse / billing cost meters
- Child-level behavior tracking
- Marks/attendance entry UIs (MRK / ATT)

## Owner test focus

Superadmin Analytics → see School health scores + Event taxonomy.
School admin Reports → see School health score.
