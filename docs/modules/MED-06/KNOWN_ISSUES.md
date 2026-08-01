# MED-06 known issues

## Keys are validated but not set

Both provider keys were validated live against their APIs on 2026-08-01 and then
cleared from the shell. They are not Edge Function secrets yet. Until the owner
pastes them in Studio, every voice and every clip fails closed with
`PROVIDER_UNCONFIGURED`, which is the correct undeployed state: every caption
and every reaction keeps its local art.

## No Fish reference_id yet

The Learning Guide speaks in Fish's stock voice. Picking a specific
`reference_id` is a new `narration_voices` row (the voice id is part of the
reuse hash), not an edit of `guide_fish_stock`.

## Cost figures are estimates

`VOICE_PROVIDER_COST_MICROS_PER_1K_CHARS` defaults to 15000 and
`VIDEO_COST_MICROS_PER_CLIP` defaults to 15000. Correct them once a real invoice
exists. The request ceilings (100 voice / 20 video per day) already stop a runaway.

## The real companion image is still unreviewed

`guide_greeting_staticArt` from the MED-05 dry run sits `ready` / `unreviewed`.
A clip of `guide_greeting` will refuse with `NM011` until a reviewer approves
that picture (or a newer one) in `1:1`. That is the gate working, not a bug.

## Deno was never on the PATH

Adapter tests for MED-03 and MED-04 had been written but never executed. This
module installed Deno into a temp directory and ran all 56; they all pass. The
install is not committed and is not on the PATH for future shells.
