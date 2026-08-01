# PROJECT_STATUS

## Current state

- **Current release:** R4 Companion
- **Current module:** MED-05 Superadmin Asset Review and Publication
- **Current status:** USER_TEST
- **Current branch:** module/MED-05-asset-review-publication
- **Last completed module:** MED-04
- **Application name:** Nano

## Releases

- R1 Identity: complete
- R2 Student Core: complete (STU-03 through STU-05 DONE)
- R3 Learning: complete (LRN-01–LRN-05, QZ-01–QZ-06 DONE)
- R4 Companion: CMP-01–CMP-03 and MED-01–MED-04 DONE; MED-05 in USER_TEST

## Owner decision waiting

`generate-asset` is **deployed** (owner approved, 2026-08-01). Images work end to
end and cost nothing: one real companion image has been generated and is sitting
unreviewed, ready for the MED-05 manual test.

Two things are still open, and both are owner decisions:

- **Voice.** `VOICE_PROVIDER_API_KEY` is unset, so narration fails closed. Only
  a Supabase Edge Function secret is needed; the Gemini TTS adapter is deployed.
- **Video.** `VIDEO_PROVIDER_API_KEY` is unset, and the adapter still defaults to
  `veo-2.0-generate-001`, which is a legacy model. Video needs both a key and a
  decision about which Veo 3.1 tier to target, because the tiers differ in price
  by roughly eight times. The `VIDEO_COST_MICROS_PER_CLIP` default of 50,000
  ($0.05) is far below any real tier, so today the 20-requests-per-day ceiling is
  the effective spend limit, not the $3.00 cost budget.

MED-05 was also built on the admin shell QZ-01 and QZ-02 shipped, because ADM-01
is still BACKLOG. ADM-01 should absorb the Moderation screen rather than replace
it.

## Next after MED-05 DONE

R4 Companion is finished once MED-05 is approved. R5 opens with XP-01 Trusted XP
Ledger, unless you want ADM-01 first so the superadmin shell stops being
borrowed.
