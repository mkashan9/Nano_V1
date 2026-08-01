# MED-09 known issues

**The poses do not move.** They are still images. A learner sees a drawing that
holds perfectly still until the reaction changes. Breathing, blink, and a mood
bounce are MED-10, and that module is what turns this pack from a picture into
a presence.

**Only one slot has published art.** `guide_greeting_staticArt` is still the
only approved per-slot picture. The other 24 slots resolve to the bundled pose
for their mood, which is by design and is the point of the floor — but it does
mean the per-slot upgrade path is proven by exactly one asset.

**The background is opaque.** Every pose carries the dark navy square from the
reference image. Inside the circular mask that reads fine and matches published
art, but Nori cannot currently be placed over arbitrary content. Revisit with
alpha when a surface needs it.

**No `@2x`/`@3x` variants.** One 512×512 file per mood. The largest place the
stage draws art is around 140 logical pixels, so 512 covers 3× density with
room, but a future full-screen companion moment would need a larger source.

**Nothing precaches.** The first frame that shows a pose decodes it. It is a
20 KB local JPEG so the cost is small, but a `precacheImage` pass at app start
would remove even that. `NoriPosePack.all` exists for exactly that and nobody
calls it yet.

**Urdu shares the art.** Deliberate — the poses carry no text — but it means a
future pose that needs to be mirrored for right-to-left has no place to say so.
