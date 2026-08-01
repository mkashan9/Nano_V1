# MED-07 — Wan 2.2 Character Animation with Compose Fallback

## Purpose

Reaction clips where the character moves, not where a camera pans across a
still. MED-06's first composed clip was rejected for looking fake; this module
is the answer the owner chose after a live probe of Wan 2.2 image-to-video.

## Deliverables

- `wan_i2v_space` generation provider as the video default
- Wan 2.2 adapter over the public Hugging Face Space
- Data-driven one-hop fallback to `json2video_compose`
- Honest provider swap recording for the review queue
- Deno adapter tests and adversarial SQL

## Rules

- Still composes only from approved companion art (MED-06 gate stays)
- The Space is not resumable; the worker holds the connection or falls back
- An i2v model can invent; MED-05 review is load-bearing
- No key, no cost recorded, no learner-facing player added

## Out of scope

- Buying a hosted Wan endpoint with an SLA
- Companion art for reactions other than greeting
- Learner-facing audio/video playback
- Recording every authored narration line
