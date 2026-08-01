# MED-11 decisions

## The clips were not rendered, and that is the point

A reaction clip is composed from an approved image. The celebration pose exists
as a bundled asset from MED-09 but had never been through review, so there was
nothing approved to compose from.

Three ways forward were available:

1. Approve the art on the owner's behalf and render. Rejected outright. The
   MED-05 gate exists precisely so that nothing reaches a child without a human
   deciding, and an agent that approves its own output to unblock itself has
   removed the gate rather than passed it.
2. Compose from the bundled file directly, bypassing `generated_assets`.
   Rejected: it would put a clip in front of learners built from art nobody
   reviewed, through a path with no provenance and no rejection route.
3. Register the art, queue it, and stop. Chosen.

The cost is that MED-11 returned in two passes rather than one. The owner
approved the art and the pack was rendered in the same session, so the cost was
one round trip.

## The clip library stayed closed

`create_reaction_clip_draft` authors a new *version* of an existing reaction and
raises `NM004` on an unknown slug. Three of the five celebration modes did not
exist as reactions, so they could not be created over the wire.

That looked like an obstacle and is actually the design working. A reaction is a
product decision — which moments deserve a clip at all — and it belongs in git
and in review rather than in whatever script happened to run. `guide`,
`explorer`, and `builder` were added by migration.

## The fallback compositor is now a test failure, not just a preference

`guide_celebration` came back from `json2video_compose` because the fallback
fired while the Wan attempt was still generating. Nothing errored. The clip was
fine-looking metadata in a table.

Three things made it worth catching rather than shrugging at: guide is the
default mode, so it is the celebration most learners reach; json2video is the
provider whose output the owner rejected twice in MED-06 for looking fake; and
it costs 15,000 micros against Wan's zero, so the whole pack would have been
free except for that one clip.

The fallback exists so a render never hard-fails, not so it can quietly become
the source of the art. A probe now fails on any approved clip from it, because
"the expensive ugly one slipped through and nobody looked" is exactly the
failure mode that does not announce itself.

## The same drawing was registered five times

Composition resolves art by slot, so a clip for `builder_celebration` needs
`builder_celebration_staticArt` specifically. MED-09 established that the mode
changes the framing and the accent rather than the character, so all five point
at byte-identical files with the same checksum.

The alternative — teaching composition to fall back to a shared celebration
image — would have put a special case in the middle of the provenance chain to
save four rows. Provenance is the part of this pipeline that has to stay
boring.

## Urdu was generated rather than assumed

The alternative was to leave Urdu unrecorded on the theory that a voice cloned
from English speech probably cannot read Urdu script well.

Generating it costs 0.005 of a cent per line and produces something a person
can actually listen to and judge. Reasoning about it produces an opinion.
Fifteen recordings of evidence beat one paragraph of speculation, and rejecting
the Urdu set later costs nothing because strict locale match already degrades a
missing recording to its caption.

## Coverage is derived, never listed

Both new tests build the reachable set from `CompanionEvent.values` and
`CompanionMood.forEvent` rather than from a hardcoded list of moods. Adding an
event to the enum is therefore enough to make the coverage test fail, which is
the only way this stays true after the module ships.

The one place a literal list survives is the recordable-slug set, and it is
there on purpose: it is a tripwire that says "the script book changed, the
narration run is now incomplete", which is a different and more useful failure
than a silently missing line.

## "A mood that can only ever be a caption" is a distinct test

The obvious coverage test is "every mood has a line". That passes for a mood
whose only line is personalised — which, under ADR-0008, is a mood that can
never be spoken however much narration is generated.

It is invisible from the outside: the caption appears, nothing is broken,
Nori is simply mute there forever. So it gets its own assertion.

## Recordings are checked against the cast provider, not the cast voice id

The SQL probe compares `provider_id` to the default voice's provider rather
than comparing voice ids directly, because the voice id is part of the reuse
hash and a re-cast creates a new row rather than editing one. Comparing ids
would fail every existing recording the moment a voice is replaced, which would
make the test noise instead of signal. Comparing providers catches the failure
that actually matters: a recording made by a provider nobody cast.

## One storage object may never serve two locales

Added as an explicit probe. Strict locale match is enforced on the client, and
this checks the same rule from the database side: if two locales ever shared a
storage path, a child who chose Urdu would hear English and every client-side
check would still pass.
