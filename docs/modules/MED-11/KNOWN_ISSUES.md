# MED-11 known issues

**The Urdu voice is unverified, and was approved anyway.** It renders. Whether
it reads Urdu as Urdu is unknown, because nobody has listened. The voice was
cast against English lines in ADR-0008 and Urdu was never part of that
decision; the owner chose to approve the set on that basis, and the review note
on every asset records it. Rejecting them later costs nothing.

**`celebration_celebration` has no 9:16 clip.** Its published direction lists
both `1:1` and `9:16`, but composition resolves art by slot *and* by shape, and
only a square source exists. The portrait variant needs a 9:16 drawing, which
is new art rather than a re-labelling of the approved one.

**The celebration art is one file registered under five slots.** Byte-identical
each time, which follows the MED-09 decision that mode does not change the
drawing. It means five review rows for one picture, and it means a future
per-mode celebration drawing has to replace five rows rather than one.

**Clips are English-locale rows although they are silent.** Every clip is
stored with `locale = en` because the pipeline requires a locale, but there is
nothing language-specific in a silent video. An Urdu learner reaching a
celebration is served the `en` row, which is correct behaviour reached by an
incorrect-looking route.

**One recording per line, no variants.** Each slug has a single take. There is
no way to prefer a warmer reading over a flatter one without rejecting and
regenerating, and regeneration is not deterministic.

**`greeting-1` is permanently silent** and always will be. It is the
personalised greeting, and ADR-0008 rules those caption-only. Home was already
pinned to `seed: 1` in MED-08 so the voiced greeting is the one learners get,
but any other surface that lands on `greeting-1` shows no Listen button and
nothing explains why to the learner.

**Coverage is checked against the script book, not against the app.** The tests
prove every line in `CompanionScriptBook` can be spoken. They do not prove that
every screen actually reaches a line — a surface that resolves to a mood with
no placement still shows nothing. That gap is MED-12's coverage gate.

**Spend is reported, not enforced, in the new probe.** The SQL test prints
total voice spend as a notice rather than failing above a threshold. The real
budget enforcement lives in the MED-02 quota path; this is only visibility.
