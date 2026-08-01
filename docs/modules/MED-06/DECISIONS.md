# MED-06 decisions

## The clip is the picture, moving

Veo was a generative substitute for a compositor. That meant a child could see a
companion that was not Nano's companion, and nobody could say in advance what the
frames would contain. json2video removes both problems: the only input is art a
reviewer already signed off. The database knows which providers compose
(`composes_from_art`) so the refusal lives where the money is committed, not
inside TypeScript after a charge.

## Motion is a closed set, not free-form movie JSON

An earlier sketch stored a full movie specification in `direction`. That would
have let a curator author anything the compositor accepted, including movements
nobody had seen rendered. Five named motions — `hold`, `settle`, `driftIn`,
`pushIn`, `dip` — are all a Ken Burns compositor can honestly do over one
picture, and each one is distinct in the rendered movie. The prose `direction`
stays for reviewers; it is never sent to json2video.

## Stock is a sentinel, not a blank

Fish identifies a voice by `reference_id`. The owner has not picked one, so the
registry says `stock` and the adapter sends no reference at all. An empty column
would have been refused by the check constraint and would have read as an
oversight; a named sentinel is a decision.

## A new voice row, not an edit of Aoede

The voice id is part of the reuse hash (MED-03). Editing `aoede` in place would
have handed Gemini recordings back for Fish requests. `guide_fish_stock` is a
new row; `aoede` is disabled.

## Gemini stays

The Gemini adapters remain registered and their provider rows remain in the
table, disabled. A rollback is an `UPDATE`, not a redeploy and not a migration
that has to invent the old rows again.

## A person may supply a picture

The compose gate needs approved companion art, and the only image provider Nano
can reach without buying one cannot produce art worth approving. Rather than
lower the gate, MED-06 added a way for a human to put a picture in:
`register_curated_asset`, plus a storage policy that lets a platform admin place
the file.

The gate itself is untouched. Curated art is registered `ready` and
`unreviewed`, joins the same queue, and is unreadable by every learner until a
reviewer approves it — `asset_object_is_published` is a lookup from the object
name to an approved row, so a file with no row, or a row nobody approved, is
unreachable. Rights are mandatory, because a picture nobody can account for is
one that cannot be defended when a school asks where it came from.

This is not only a workaround. The handbook's asset ladder begins at Tier 0
static art, and static art is drawn by a person far more often than it is
generated, so Nano needed this door regardless of which provider it buys next.

## A curated upload is a provider row

Calling a human a "provider" is a small lie that buys a large simplicity:
`provider_id` is already a foreign key, every reader already renders a provider,
and a reviewer learns where a picture came from in the column they were reading
anyway. `curated_upload` is enabled but never default — an unqualified request
for an image is a request to *generate* one, and a default that cannot generate
would turn every such request into a failure nobody asked for.

## Composition facts are stamped at the ask

A composed render spans two invocations, and only the first knows which picture
was used. Re-resolving at collection time answers the wrong question — what is
approved now, not what was animated — and answers nothing if the art has since
been rejected. So `request_reaction_clip` stamps the motion and the source
asset id onto the row when it already has them, and
`record_generated_asset_result` merges provenance while stripping nulls so a
worker reporting ignorance cannot erase knowledge.

## The reviewer plays the file, in the browser, with no plugin

MED-03 and MED-04 left voice and video unplayable and said so, on the reasoning
that a player meant a plugin in every app. That reasoning does not survive
contact with the Moderation queue: asking somebody whether a child should see a
clip while showing them a checksum is not a review, it is a signature. The
first owner to reach the queue with a real MP4 and a real MP3 in it asked how to
play them, which settles the question.

admin_web is the one app that only ever runs in a browser, and a browser plays
MP3 and MP4 already. A conditional import gives the web build real `<audio>` and
`<video>` elements through `package:web` — wasm-clean, unlike `dart:html` — and
gives everything else a stub that returns nothing, so the VM widget tests keep
exercising the old metadata fallback. The student and teacher apps gain no
player and no dependency.

The fallback stays reachable on purpose. A preview that will not load must leave
Reject working, because rejecting is the safe direction.

## Cost estimates are non-zero by default

A cost budget that reads zero for every recording and every clip is a cost
budget that never stops anything (MED-02). Both new adapters default to a
conservative estimate; the owner corrects them against real invoices later.
Urdu is billed by UTF-8 bytes, the way Fish counts it.
