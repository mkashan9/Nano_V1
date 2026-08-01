# MED-07 known issues

## The Space has no SLA

`cinderholm/wan2-2-i2v-v3` is owned by a stranger. It can sleep, queue, or
disappear. That is why `json2video_compose` stays as the automatic fallback.
When the Space is down, a reaction still gets a clip — a worse-looking one —
rather than nothing.

## Coverage is capped by approved art

Only `guide_greeting` has approved companion art. Celebration and quizCoach
reactions refuse with `NM011` until art exists for them. Buying an image
provider that can draw, or supplying more curated pictures, is an owner
decision outside this module.

## No learner-facing player

admin_web can play the clip. `student_app` still cannot. Approved media sits
in the catalog until a separate module attaches a player. That gap is older
than MED-07 and is not owned by it.

## Deno is not on the PATH

Adapter tests were run with a temp install of Deno 2.9.4. The install is not
committed and is not on the PATH for future shells.
