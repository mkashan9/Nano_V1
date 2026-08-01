# MED-01 plan

1. Widen the module spec: the stub allowed docs only, but the module ships
   database, function, and package code.
2. Model the data first — provider registry, assets, attempts — so the rules live
   where they cannot be bypassed by a client.
3. Add the hash and the reuse index before any provider call exists, so the
   cheapest path is the default one.
4. Split authority: request by the caller's own token, claim and record by the
   service role only.
5. Apply to the classified development project and attack it with SQL: learner,
   superadmin, and worker, plus duplicate callbacks and retries.
6. Write the Edge Function around the adapter contract, keyless image path first,
   and make a missing key an ordinary recorded failure.
7. Give Dart a read contract and a fake, then the catalog that feeds the CMP-01
   ladder and drops a rung when a file is absent.
8. Fix whatever the database linter finds before documenting.
9. Document, including what is deliberately not deployed, and hand the owner a
   test that needs no Docker.
