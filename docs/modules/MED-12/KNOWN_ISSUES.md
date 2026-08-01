# MED-12 known issues

**Game surface is not mounted.** Policy says visible; product mount set
excludes it until GME-01.

**Learning catalog and subject list have no companion.** Only the topic player
mounts on the learning surface. Catalog browsing stays quiet on purpose for
now; empty progress already carries the empty-state moment.

**Onboarding only mounts on the welcome step.** Later onboarding steps are
forms; the policy surface is `onboarding` for the whole flow, but only welcome
fires `appOpen`.

**Companion name on results comes from the session controller.** If the page's
`companionName` prop and the controller's name diverge, the badge follows the
controller. Pages that rename Nori mid-session without rebuilding the
controller will show the old name until the next session scope rebuild.
