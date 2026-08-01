# MED-11 known issues

**The celebration clip pack is not rendered.** Blocked, deliberately, on the
owner approving the celebration source art. Two of the five celebration slugs
are authored (`celebration_celebration`, `quizCoach_celebration`); `guide`,
`explorer`, and `builder` have no draft yet.

**The Urdu voice is unverified.** It renders. Whether it reads Urdu as Urdu is
unknown until someone listens. The voice was cast against English lines in
ADR-0008 and Urdu was never part of that decision.

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
