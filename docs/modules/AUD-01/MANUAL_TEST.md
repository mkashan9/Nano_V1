# AUD-01 Manual Test Guide

## How to run / inspect

1. Open the Nano workspace root.
2. Confirm `api_s.txt` and `github.txt` are **not** present.
3. Confirm `supabase/functions/.env.local` exists on your machine (ignored) and `.env.example` has names only.
4. Skim:
   - `docs/audits/BOOTSTRAP_AUDIT.md`
   - `docs/audits/SECURITY_AND_SECRETS_AUDIT.md`
   - `docs/handbook/NANO_HANDBOOK.md` (existence + headings)
   - `docs/handbook/HANDBOOK_TRACEABILITY.md`
   - `docs/audits/UI_REFERENCE_CATALOG.md`
   - `MODULE_STATUS.md`
   - `AGENTS.md`

## Checklist

- [ ] Root has no plaintext credential files
- [ ] Handbook markdown opens and looks complete
- [ ] UI catalog lists Junior (`kids`) and Senior (`four_12`) screens
- [ ] Only AUD-01 is ACTIVE / USER_TEST
- [ ] Next eligible module after approval is FND-01
- [ ] You accept treating remote `nano_v1` as production-like until classified
- [ ] Optional: start Docker Desktop so SEC-01 can use local Supabase later
- [ ] Optional: add `read:org` to GitHub PAT for full `gh auth login`

## Approve

Reply `NEXT` if the audit baseline is accepted.

## Reject / fix

Reply `FIX: <problem>` describing the issue.
