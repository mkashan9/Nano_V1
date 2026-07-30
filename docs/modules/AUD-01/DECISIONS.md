# AUD-01 Decisions

1. **Automation queue granularity** — Use the master automation prompt’s 120-module queue even when the handbook uses coarser IDs; map via `HANDBOOK_TRACEABILITY.md`.
2. **Soft dependency adjustments** — `LRN-04` does not hard-depend on `CMP-01`; `QZ-01` does not hard-depend on `ADM-01`; documented for eligibility.
3. **Remote Supabase** — `nano_v1` treated as production-like; no remote schema writes in AUD-01.
4. **GitHub auth** — GCM stores credentials; `gh auth login` blocked by missing `read:org`; API access verified.
5. **Image provider** — Pollinations documented as default image route; privileged video/voice keys in Edge Function env only.
6. **avatar_trials** — Quarantined; not fixed in AUD-01 (debt recorded).
