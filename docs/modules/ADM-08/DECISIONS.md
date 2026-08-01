# ADM-08 decisions

## Safe aggregates only

Reuse ADM-01 privacy rejection (`PlatformDashboard.isPrivacySafePayload`). No
email, guardian, marks, attendance, display names, or actor ids.

## Distinct from Platform home

ADM-01 remains the directory + overview home. ADM-08 focuses on ops health,
catalog readiness, and short-window activity for the Analytics destination.

## No event pipeline yet

Do not create `analytics_events`. ANA-01 owns product taxonomy and school health.
