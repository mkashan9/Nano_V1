# Nori — canonical character sheet

Locked: 2026-08-01 (MED-09). Version `v1`.

This is the description every pose is judged against. It exists because
character drift is the expected failure of generating a mascot one pose at a
time: each image is plausible on its own and the set is not one character. A
reviewer approving a pose is answering one question — *is this the same Nori?*
— and this page is what "the same" means.

The reference image is the approved `guide_greeting_staticArt`, the first art
the owner accepted. Every pose in the pack was generated conditioned on it.

## Identity

Nori is a small, soft, floating creature. Not an animal, not a robot, not a
person. Closest read is a friendly rounded blob or spirit. Nori has no gender
and no age; the guide voice cast in ADR-0008 is a female teacher register and
is deliberately *not* Nori's own voice — it is the guiding voice beside her.

## Silhouette

- Body is a single rounded egg or teardrop, widest at the bottom, tilted
  slightly. No neck, no separate head — the face sits on the upper body.
- Two short soft ear nubs on the top of the head, leaning slightly to the
  character's left. The taller one is a rounded leaf shape; the shorter one
  sits beside it.
- Two small stubby rounded arms, no hands with fingers except where a pose
  needs a soft mitten-like point.
- No legs. Nori floats, resting above a soft elliptical purple glow-shadow.

## Colour

| Part | Colour |
|------|--------|
| Body | Purple to violet vertical gradient, roughly `#8B5CF6` into `#A78BFA` |
| Belly patch | Large lighter lavender oval on the lower front, roughly `#C4B5FD` |
| Eyes | Very dark plum, near black, with one large white circular highlight each |
| Blush | Soft pink ovals on both cheeks, roughly `#F9A8D4` |
| Mouth | Dark plum opening with a coral-pink tongue when open |
| Background | Solid very dark navy, roughly `#161A33` |
| Under-glow | Soft purple ellipse beneath the body |

## Face

- Eyes are very large relative to the head, glossy, with a big white highlight
  in the upper area. They carry almost all of the expression.
- Eyebrows are thin single curved strokes. They move; they never become thick
  or angry.
- Blush is always present. It brightens for celebration and never disappears.

## Style

Soft airbrushed shading, fully rounded shapes, no hard outlines, no visible
linework. Children's app mascot. Rendered flat 2D with soft volume, not a 3D
render and not a vector with flat fills.

## Framing

Square, 1:1, centred, generous margin so the character is never cropped by the
circular mask the stage draws. The stage clips art to a circle and draws the
mode ring and emblem around it, so nothing important may sit in the corners.

## What is fixed and what may vary

Fixed in every pose: silhouette, ear nubs, belly patch, colour palette, eye
design, blush, style, background, framing.

May vary by mood: arm position, mouth shape, eyebrow angle, eye shape (open,
happy arcs, glancing), body tilt and stretch, and small sparkle accents for
celebration only.

**Mode never varies the art.** Guide, Explorer, Quiz Coach, Builder, and
Celebration are the same Nori. CMP-02 defines a mode as a shared face and
emblem with a changed accent and framing, and the stage supplies both. This is
why the bundled pack is one drawing per mood rather than one per slot.

## Rejection triggers

Reject a pose that shows any of these, however good it looks:

- A different silhouette: rounded rectangle, circle, animal, humanoid
- Missing or relocated ear nubs, missing belly patch
- Added features: legs, feet, fingers as separate digits, clothing, hats, props
- Hard outlines, flat vector fills, or a 3D render look
- A different palette, a light background, or a lost under-glow
- Eyes that are small, sharp, side-pupilled, or missing the highlight
- Text, letters, numbers, or UI in the frame
- Anything frightening, sad, crying, or scolding — Nori is never disappointed
  in a child

## Mood pack

| Mood | Pose | Bundled file |
|------|------|--------------|
| greeting | One arm raised waving, open smile, motion arcs | `nori_greeting.jpg` |
| idle | Arms low and relaxed, closed soft smile, still | `nori_idle.jpg` |
| point | One arm extended pointing out and up, bright open smile | `nori_point.jpg` |
| thinking | One arm to the chin, eyes glancing up, pursed mouth | `nori_thinking.jpg` |
| gentleRetry | One arm open palm-up offering, kind closed smile, empathetic brows | `nori_gentle_retry.jpg` |
| celebration | Both arms up, happy arc eyes, wide grin, sparkles | `nori_celebration.jpg` |

Bundled files live in `packages/nano_design_system/assets/companion/` at
512×512 JPEG, about 135 KB for the set.
