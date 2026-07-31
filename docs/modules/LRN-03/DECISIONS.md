# LRN-03 decisions

## The client reports position, never progress

LRN-02 accepted a progress fraction from the client. That was a claim the
server could not check, so `save_topic_progress` is gone. Its replacement,
`record_playback_heartbeat`, takes only the player position and derives credit
from wall-clock elapsed since the previous beat. Progress and completion are
now consequences of time the server itself observed.

## Credit rule lives in one function

`nano_internal.playback_credit(position_delta, elapsed_seconds)` grants the
smallest of: how far the position moved, elapsed wall clock plus 25% jitter,
and a 120 second per-beat ceiling. Seeking forward moves the position without
moving the clock, so it earns nothing. `PlaybackPolicy.creditFor` mirrors it on
the client purely so the UI can predict what the server will say.

## Completion is a row, not a flag

`public.topic_completions` has a unique key on (learner, topic version), so
"completion cannot be duplicated" is enforced by the database rather than by a
code path. `complete_topic` returns the existing progress row unchanged when
the learner is already finished, writes one audit event, and never lets the
client choose the threshold.

## Retries are safe

A repeated heartbeat carries the same position, so the delta is zero and the
credit is zero. A dropped beat costs at most one interval; the next beat
credits from wherever the head is, still bounded by elapsed time.

## Idempotency covers the failure the handbook names

Handbook LRN-02 asks for heartbeats that retry with idempotency and completion
events that are validated. Both live in the RPCs, so an offline client can
replay whatever it queued without inflating watch time.

## SECURITY DEFINER is intentional

`record_playback_heartbeat` and `complete_topic` are definer functions because
`learning_progress` and `topic_completions` deny direct writes. They pin
`search_path`, act only on `auth.uid()`, and refuse locked or unpublished
topics through `nano_internal.assert_topic_writable`.

## Playback surface is a placeholder

Approved provider playback belongs to MED-01, so the player renders a framed
placeholder driven by a one-second clock. Every other part of the session —
resume, accounting, captions, completion — is the real path, so swapping the
surface later does not change the server contract.
