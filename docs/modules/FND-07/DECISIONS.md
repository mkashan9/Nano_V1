# FND-07 Decisions

- Classroom Mode forces reduced motion and mutes sound/haptics without clearing the user's saved toggles.
- Sound is preference-gated only in R0 (no audio assets yet).
- System `MediaQuery.disableAnimations` and prefs both zero non-essential `NanoMotion` durations.
- Persistence of preferences is deferred to profile/onboarding modules.
