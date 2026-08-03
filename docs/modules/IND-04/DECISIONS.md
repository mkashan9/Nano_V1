# IND-04 — Decisions

1. **Fake-first redeem.** Invite preview/link is client-seeded; live school
   membership RPC waits for a later schema pass.
2. **Progress always preserved.** Link result carries `progressPreserved: true`
   as the product rule; the fake never invents a wipe.
3. **Independents only.** School-linked learners cannot re-link via this path.
4. **Default upgrade is senior + Flex.** Junior track still wins presentation
   when `experienceTrack` is junior.
5. **Suspended schools refuse link.** Preview may load; confirm is denied.
