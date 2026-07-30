# GitHub Repository Settings (Owner Action)

Repository: `mkashan9/Nano_V1`

## Required

1. Default branch: `main`
2. Branch protection on `main`:
   - Require pull request before merging
   - Require status checks (CI workflows)
   - Do not allow force pushes
   - Do not allow deletions
3. Do not auto-deploy to production
4. Secret scanning / push protection enabled
5. Dependency review enabled if available

## GitHub token scopes

Current token scopes observed: `repo`, `write:packages`.

`gh auth login` also expects `read:org`. Owner should regenerate or amend the PAT to include `read:org` for full GitHub CLI login, or continue using Git Credential Manager + session `GH_TOKEN` for `gh` API calls.

## CI workflow install (blocked on first push)

The PAT used for bootstrap lacks the workflow scope, so GitHub rejected pushing .github/workflows/ci.yml.

Owner action:

1. Add the `workflow` scope to the GitHub PAT (and ideally `read:org`).
2. Copy `docs/setup/ci.yml.pending` to `.github/workflows/ci.yml`.
3. Commit on a follow-up branch or during FND-01.
