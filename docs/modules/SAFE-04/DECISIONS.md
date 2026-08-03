# SAFE-04 decisions

## Defaults off

Platform and school communities start disabled. Schools must opt in after the
platform switch is on.

## Junior hard block

Entitlement requires `student_onboarding.experience_track = 'senior'`.
Missing or junior track never enables Communities, regardless of admin toggles.

## Independent learners

Independent seniors need only the platform switch (no school row).

## School students

Require platform AND their school's opt-in, resolved via active student
membership (profiles have no `school_id` column).

## Client flag is advisory

Nav uses `featureFlags['communities']` from bootstrap. Server helpers remain
authoritative for COM mutations.
