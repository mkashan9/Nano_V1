# MED-02 plan

1. Widen the module spec: the stub allowed docs only, but the module ships
   database, function, package, and app code.
2. Decide the charging order before writing anything, because it is the one
   decision the rest depends on: reuse first, budget second.
3. Model budgets and usage by scope, so a limit can be per platform, per feature,
   or per school, and per kind or over all kinds together.
4. Rewrite `request_generated_asset` around the new order, and make the result
   path charge the provider's real cost.
5. Open the delivery gate: an approved file readable by any signed-in client, so
   the client can mint its own signed URL and let the CDN cache the bytes.
6. Attack it with SQL: a spent budget, a spent feature, a reused ask, a duplicated
   callback, an unapproved file, and a learner looking at all of it.
7. Give the client a cache that asks rarely and cannot fail, and name the reasons
   a reaction falls back.
8. Wire it into the student app so `clipsAvailable` is finally real, and prove with
   a widget test that a broken catalog is invisible.
9. Document what is enforced, what is deliberately not editable yet, and what has
   still never run.
